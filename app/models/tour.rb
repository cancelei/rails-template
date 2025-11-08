# == Schema Information
#
# Table name: tours
#
#  id                     :bigint           not null, primary key
#  booking_deadline_hours :integer
#  bookings_count         :integer          default(0), not null
#  capacity               :integer          not null
#  currency               :string
#  current_headcount      :integer          default(0)
#  description            :text
#  ends_at                :datetime         not null
#  latitude               :float
#  location_name          :string
#  longitude              :float
#  price_cents            :integer
#  starts_at              :datetime         not null
#  status                 :integer          default("scheduled")
#  title                  :string           not null
#  tour_type              :integer          default("public_tour"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  guide_id               :bigint           not null
#
# Indexes
#
#  index_tours_on_guide_id   (guide_id)
#  index_tours_on_starts_at  (starts_at)
#  index_tours_on_status     (status)
#  index_tours_on_tour_type  (tour_type)
#
# Foreign Keys
#
#  fk_rails_...  (guide_id => users.id)
#
class Tour < ApplicationRecord
  include ActionView::RecordIdentifier

  # Ignore removed columns for safe deployment
  self.ignored_columns += ["cover_image_url"]

  belongs_to :guide, class_name: "User"

  has_many :bookings, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :weather_snapshots, dependent: :destroy
  has_many :tour_add_ons, dependent: :destroy

  # Active Storage attachments
  has_one_attached :cover_image
  has_many_attached :images

  enum :status, { scheduled: 0, ongoing: 1, done: 2, cancelled: 3 }
  enum :tour_type, { public_tour: 0, private_tour: 1 }

  # Available booking deadline hour options
  BOOKING_DEADLINE_OPTIONS = [1, 2, 3, 6, 12, 24, 48, 72].freeze

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 2000 }
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :booking_deadline_hours,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            if: :private_tour?
  validate :ends_after_starts
  validate :booking_deadline_hours_before_start, if: :private_tour?
  validate :cover_image_format
  validate :images_format
  validate :images_limit

  # Calculate the actual booking deadline datetime from hours before tour start
  def booking_deadline
    return nil unless private_tour? && booking_deadline_hours && starts_at

    starts_at - booking_deadline_hours.hours
  end

  def ends_after_starts
    return unless starts_at && ends_at && ends_at <= starts_at

    errors.add(:ends_at, "must be after starts_at")
  end

  def booking_deadline_hours_before_start
    return unless booking_deadline_hours && starts_at

    deadline = starts_at - booking_deadline_hours.hours
    return if deadline < starts_at

    errors.add(:booking_deadline_hours, "must result in a deadline before tour start time")
  end

  def booked_spots
    bookings.confirmed.sum(:spots)
  end

  def available_spots
    capacity - booked_spots
  end

  def can_book?
    return false unless scheduled? && starts_at > Time.current

    if private_tour?
      # For private tours: must be before deadline and completely unboked
      bookings.confirmed.none? && booking_deadline && Time.current < booking_deadline
    else
      # For public tours: just need available spots
      available_spots > 0
    end
  end

  def booking_deadline_passed?
    private_tour? && booking_deadline && Time.current >= booking_deadline
  end

  def fully_booked?
    if private_tour?
      bookings.confirmed.any?
    else
      available_spots <= 0
    end
  end

  def past?
    ends_at < Time.current
  end

  def upcoming?
    starts_at > Time.current
  end

  def duration_minutes
    return nil unless starts_at && ends_at

    ((ends_at - starts_at) / 60).to_i
  end

  def max_spots
    capacity
  end

  # Active Storage helper methods
  def cover_image_url(variant: :medium)
    return unless cover_image.attached?

    case variant
    when :thumbnail
      Rails.application.routes.url_helpers.url_for(cover_image.variant(resize_to_limit: [150, 150]))
    when :medium
      Rails.application.routes.url_helpers.url_for(cover_image.variant(resize_to_limit: [400, 400]))
    when :large
      Rails.application.routes.url_helpers.url_for(cover_image.variant(resize_to_limit: [1200, 800]))
    else
      Rails.application.routes.url_helpers.url_for(cover_image)
    end
  rescue StandardError
    nil
  end

  def cover_image_url_or_fallback
    cover_image_url || "https://via.placeholder.com/400x300?text=No+Image"
  end

  def gallery_images?
    images.attached? && images.any?
  end

  def gallery_image_urls(variant: :medium)
    return [] unless gallery_images?

    images.filter_map do |image|
      case variant
      when :thumbnail
        Rails.application.routes.url_helpers.url_for(image.variant(resize_to_limit: [150, 150]))
      when :medium
        Rails.application.routes.url_helpers.url_for(image.variant(resize_to_limit: [800, 600]))
      when :large
        Rails.application.routes.url_helpers.url_for(image.variant(resize_to_limit: [1600, 1200]))
      else
        Rails.application.routes.url_helpers.url_for(image)
      end
    rescue StandardError
      nil
    end
  end

  # Turbo Stream broadcasts for real-time updates
  after_create_commit :broadcast_tour_created
  after_update_commit :broadcast_tour_updated
  after_destroy_commit :broadcast_tour_removed

  private

  def cover_image_format
    return unless cover_image.attached?

    acceptable_types = ["image/png", "image/jpeg", "image/jpg", "image/webp"]
    return if acceptable_types.include?(cover_image.content_type)

    errors.add(:cover_image, "must be a PNG, JPEG, or WEBP image")

    # Check file size (5MB max)
    max_size = 5.megabytes
    return unless cover_image.byte_size > max_size

    errors.add(:cover_image, "is too large (maximum is 5MB)")
  end

  def images_format
    return unless images.attached?

    acceptable_types = ["image/png", "image/jpeg", "image/jpg", "image/webp"]
    images.each do |image|
      unless acceptable_types.include?(image.content_type)
        errors.add(:images, "must be PNG, JPEG, or WEBP images")
        break
      end

      # Check file size (5MB max per image)
      max_size = 5.megabytes
      if image.byte_size > max_size
        errors.add(:images, "each image must be less than 5MB")
        break
      end
    end
  end

  def images_limit
    return unless images.attached?

    max_images = 10
    return unless images.count > max_images

    errors.add(:images, "cannot have more than #{max_images} images")
  end

  def broadcast_tour_created
    # Broadcast to admin tours index
    broadcast_prepend_to(
      "admin_tours",
      target: "tours_table_body",
      partial: "admin/tours/tour",
      locals: { tour: self }
    )

    # Broadcast to guide's dashboard
    broadcast_prepend_to(
      "guide_#{guide_id}_tours",
      target: "guide_tours_list",
      partial: "guides/dashboard/tour_card",
      locals: { tour: self }
    )
  end

  def broadcast_tour_updated
    # Broadcast to admin tours index
    broadcast_replace_to(
      "admin_tours",
      target: self,
      partial: "admin/tours/tour",
      locals: { tour: self }
    )

    # Broadcast to guide's dashboard
    broadcast_replace_to(
      target: self,
      partial: "guides/dashboard/tour_card",
      locals: { tour: self }
    )

    # Broadcast to admin guide profile page
    broadcast_replace_to(
      "admin_guide_#{guide_id}_tours",
      target: dom_id(self),
      partial: "admin/guide_profiles/tour_row",
      locals: { tour: self }
    )
  end

  def broadcast_tour_removed
    # Broadcast to admin tours index
    broadcast_remove_to "admin_tours", target: self

    # Broadcast to guide's dashboard
    broadcast_remove_to "guide_#{guide_id}_tours", target: self

    # Broadcast to admin guide profile page
    broadcast_remove_to "admin_guide_#{guide_id}_tours", target: self
  end
end
