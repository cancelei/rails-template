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
FactoryBot.define do
  factory :tour do
    guide factory: %i[user guide]
    title { "Amazing #{Faker::Adjective.positive} Tour" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    status { :scheduled }
    capacity { 10 }
    price_cents { 5000 }
    currency { "USD" }
    location_name { Faker::Address.city }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    starts_at { 1.week.from_now }
    ends_at { 2.weeks.from_now }
    current_headcount { 0 }

    trait :private_tour do
      tour_type { :private_tour }
      booking_deadline_hours { 24 }
    end
  end
end
