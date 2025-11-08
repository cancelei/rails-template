# == Schema Information
#
# Table name: bookings
#
#  id           :bigint           not null, primary key
#  booked_email :string           not null
#  booked_name  :string           not null
#  created_via  :string           default("guest_booking")
#  spots        :integer          default(1)
#  status       :integer          default("confirmed")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tour_id      :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_bookings_on_booked_email  (booked_email)
#  index_bookings_on_tour_id       (tour_id)
#  index_bookings_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (tour_id => tours.id)
#  fk_rails_...  (user_id => users.id)
#
class Booking < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :tour, counter_cache: true
  belongs_to :user
  has_one :review, dependent: :destroy
  has_many :booking_add_ons, dependent: :destroy
  has_many :tour_add_ons, through: :booking_add_ons

  enum :status, { confirmed: 0, cancelled: 1 }
  enum :created_via, { guest_booking: "guest_booking", user_portal: "user_portal" }

  before_validation :set_booked_details_from_user

  validates :booked_name, presence: true, length: { maximum: 100 }
  validates :booked_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :spots, presence: true, numericality: { greater_than: 0 }
  validate :spots_within_capacity
  validate :private_tour_booking_restrictions
  validate :booking_deadline_not_passed

  def cancel!
    return false if cancelled?

    update(status: :cancelled)
  end

  def tour_price
    return 0 unless tour&.price_cents

    tour.price_cents * spots
  end

  def add_ons_total
    booking_add_ons.sum(&:total_price)
  end

  def total_price_with_add_ons
    tour_price + add_ons_total
  end

  def formatted_total_price
    price_in_currency = total_price_with_add_ons / 100.0
    ActionController::Base.helpers.number_to_currency(
      price_in_currency,
      unit: tour&.currency == "BRL" ? "R$" : "$",
      precision: 2
    )
  end

  private

  def set_booked_details_from_user
    return unless user

    self.booked_name ||= user.name.presence || user.email
    self.booked_email ||= user.email
    self.created_via = "user_portal" if created_via == "guest_booking"
  end

  def spots_within_capacity
    return unless tour && spots > tour.available_spots

    errors.add(:spots, "exceeds available spots")
  end

  def private_tour_booking_restrictions
    return unless tour&.private_tour?
    return if tour.bookings.confirmed.none? # Allow first booking

    # For private tours, once someone books, no one else can book
    errors.add(:base, "This private tour has already been booked") if tour.bookings.confirmed.where.not(id:).any?

    # For private tours, spots must equal capacity
    return unless spots != tour.capacity

    errors.add(:spots, "must be #{tour.capacity} for private tours (full capacity required)")
  end

  def booking_deadline_not_passed
    return unless tour&.private_tour?
    return unless tour.booking_deadline

    return unless Time.current >= tour.booking_deadline

    errors.add(:base, "Booking deadline has passed for this private tour")
  end

  # Turbo Stream broadcasts for real-time updates
  after_create_commit :broadcast_booking_created
  after_update_commit :broadcast_booking_updated
  after_destroy_commit :broadcast_booking_removed

  def broadcast_booking_created
    # Broadcast to admin
    broadcast_prepend_to(
      "admin_bookings",
      target: "bookings_table_body",
      partial: "admin/bookings/booking",
      locals: { booking: self }
    )

    # Broadcast to guide's dashboard - update the tour card
    broadcast_replace_to(
      "guide_#{tour.guide_id}_tours",
      target: dom_id(tour),
      partial: "guides/dashboard/tour_card",
      locals: { tour: tour.reload }
    )

    # Broadcast to admin guide profile page if viewing this guide
    broadcast_replace_to(
      "admin_guide_#{tour.guide_id}_tours",
      target: dom_id(tour),
      partial: "admin/guide_profiles/tour_row",
      locals: { tour: tour.reload }
    )
  end

  def broadcast_booking_updated
    # Broadcast to admin
    broadcast_replace_to(
      "admin_bookings",
      target: self,
      partial: "admin/bookings/booking",
      locals: { booking: self }
    )

    # Update tour card on guide dashboard
    broadcast_replace_to(
      "guide_#{tour.guide_id}_tours",
      target: dom_id(tour),
      partial: "guides/dashboard/tour_card",
      locals: { tour: tour.reload }
    )

    # Update tour on admin guide profile page
    broadcast_replace_to(
      "admin_guide_#{tour.guide_id}_tours",
      target: dom_id(tour),
      partial: "admin/guide_profiles/tour_row",
      locals: { tour: tour.reload }
    )
  end

  def broadcast_booking_removed
    # Broadcast to admin
    broadcast_remove_to "admin_bookings", target: self

    # Update tour card on guide dashboard
    broadcast_replace_to(
      "guide_#{tour.guide_id}_tours",
      target: dom_id(tour),
      partial: "guides/dashboard/tour_card",
      locals: { tour: tour.reload }
    )

    # Update tour on admin guide profile page
    broadcast_replace_to(
      "admin_guide_#{tour.guide_id}_tours",
      target: dom_id(tour),
      partial: "admin/guide_profiles/tour_row",
      locals: { tour: tour.reload }
    )
  end
end
