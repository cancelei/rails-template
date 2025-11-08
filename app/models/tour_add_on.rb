# frozen_string_literal: true

# == Schema Information
#
# Table name: tour_add_ons
#
#  id               :bigint           not null, primary key
#  active           :boolean          default(TRUE), not null
#  addon_type       :integer          default("transportation"), not null
#  currency         :string           default("BRL"), not null
#  description      :text
#  maximum_quantity :integer
#  name             :string           not null
#  position         :integer          default(0)
#  price_cents      :integer          not null
#  pricing_type     :integer          default("per_person"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  tour_id          :bigint           not null
#
# Indexes
#
#  index_tour_add_ons_on_active                (active)
#  index_tour_add_ons_on_tour_id               (tour_id)
#  index_tour_add_ons_on_tour_id_and_position  (tour_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (tour_id => tours.id)
#
class TourAddOn < ApplicationRecord
  belongs_to :tour
  has_many :booking_add_ons, dependent: :destroy
  has_many :bookings, through: :booking_add_ons

  # Enums
  enum :addon_type, {
    transportation: 0,
    food_beverage: 1,
    photography: 2,
    equipment: 3
  }, prefix: true

  enum :pricing_type, {
    per_person: 0,
    flat_fee: 1
  }, prefix: true

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :addon_type, presence: true
  validates :pricing_type, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :maximum_quantity, numericality: { greater_than: 0 }, allow_nil: true

  # Custom validation: limit add-ons per tour
  validate :tour_add_ons_limit

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_position, -> { order(:position) }
  scope :by_type, ->(type) { where(addon_type: type) }

  # Callbacks
  before_create :set_position

  # Instance methods
  def formatted_price
    return "Free" if price_cents.zero?

    price_in_currency = price_cents / 100.0
    formatted = ActionController::Base.helpers.number_to_currency(
      price_in_currency,
      unit: currency_symbol,
      precision: 2
    )

    pricing_type_per_person? ? "#{formatted} per person" : formatted
  end

  def total_price(num_guests = 1)
    pricing_type_per_person? ? price_cents * num_guests : price_cents
  end

  def currency_symbol
    case currency
    when "BRL"
      "R$"
    when "USD"
      "$"
    when "EUR"
      "€"
    else
      currency
    end
  end

  def addon_type_icon
    case addon_type
    when "transportation"
      "🚗"
    when "food_beverage"
      "🍽️"
    when "photography"
      "📸"
    when "equipment"
      "🎒"
    else
      "➕"
    end
  end

  private

  def tour_add_ons_limit
    return unless tour

    return unless tour.tour_add_ons.count >= 10 && new_record?

    errors.add(:base, "Cannot add more than 10 add-ons per tour")
  end

  def set_position
    return if position.present?

    max_position = tour.tour_add_ons.maximum(:position) || -1
    self.position = max_position + 1
  end
end
