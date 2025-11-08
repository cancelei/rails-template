# frozen_string_literal: true

# == Schema Information
#
# Table name: booking_add_ons
#
#  id                     :bigint           not null, primary key
#  price_cents_at_booking :integer          not null
#  quantity               :integer          default(1), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  booking_id             :bigint           not null
#  tour_add_on_id         :bigint           not null
#
# Indexes
#
#  index_booking_add_ons_on_booking_id                     (booking_id)
#  index_booking_add_ons_on_booking_id_and_tour_add_on_id  (booking_id,tour_add_on_id) UNIQUE
#  index_booking_add_ons_on_tour_add_on_id                 (tour_add_on_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (tour_add_on_id => tour_add_ons.id)
#
class BookingAddOn < ApplicationRecord
  belongs_to :booking
  belongs_to :tour_add_on

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_cents_at_booking, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tour_add_on_id, uniqueness: { scope: :booking_id, message: "has already been added to this booking" }

  # Custom validations
  validate :quantity_within_maximum

  # Callbacks
  before_validation :set_price_at_booking, on: :create

  # Instance methods
  def total_price
    if tour_add_on.pricing_type_per_person?
      price_cents_at_booking * booking.spots * quantity
    else
      price_cents_at_booking * quantity
    end
  end

  def formatted_price
    price_in_currency = total_price / 100.0
    ActionController::Base.helpers.number_to_currency(
      price_in_currency,
      unit: tour_add_on.currency_symbol,
      precision: 2
    )
  end

  def unit_price
    price_cents_at_booking
  end

  def formatted_unit_price
    price_in_currency = unit_price / 100.0
    ActionController::Base.helpers.number_to_currency(
      price_in_currency,
      unit: tour_add_on.currency_symbol,
      precision: 2
    )
  end

  private

  def set_price_at_booking
    self.price_cents_at_booking ||= tour_add_on.price_cents
  end

  def quantity_within_maximum
    return unless tour_add_on&.maximum_quantity

    return unless quantity > tour_add_on.maximum_quantity

    errors.add(:quantity, "cannot exceed maximum of #{tour_add_on.maximum_quantity}")
  end
end
