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
FactoryBot.define do
  factory :tour_add_on do
    tour
    sequence(:name) { |n| "Add-on #{n}" }
    description { "A great add-on to enhance your tour experience" }
    addon_type { :transportation }
    price_cents { 2500 }
    currency { "BRL" }
    pricing_type { :per_person }
    maximum_quantity { nil }
    active { true }
    position { 0 }

    trait :transportation do
      addon_type { :transportation }
      name { "Hotel Pickup" }
      description { "Convenient pickup from your hotel" }
      price_cents { 2000 }
    end

    trait :food_beverage do
      addon_type { :food_beverage }
      name { "Lunch Package" }
      description { "Delicious local lunch included" }
      price_cents { 3500 }
    end

    trait :photography do
      addon_type { :photography }
      name { "Professional Photos" }
      description { "Professional photographer captures your tour" }
      price_cents { 5000 }
      pricing_type { :flat_fee }
    end

    trait :equipment do
      addon_type { :equipment }
      name { "Equipment Rental" }
      description { "High-quality equipment for your tour" }
      price_cents { 1500 }
    end

    trait :per_person do
      pricing_type { :per_person }
    end

    trait :flat_fee do
      pricing_type { :flat_fee }
    end

    trait :inactive do
      active { false }
    end

    trait :with_maximum_quantity do
      maximum_quantity { 5 }
    end
  end
end
