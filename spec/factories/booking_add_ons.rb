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
FactoryBot.define do
  factory :booking_add_on do
    booking
    tour_add_on
    quantity { 1 }
    price_cents_at_booking { tour_add_on&.price_cents || 2500 }

    trait :with_quantity do
      transient do
        item_count { 2 }
      end
      quantity { item_count }
    end

    trait :per_person_pricing do
      tour_add_on factory: %i[tour_add_on per_person]
    end

    trait :flat_fee_pricing do
      tour_add_on factory: %i[tour_add_on flat_fee]
    end
  end
end
