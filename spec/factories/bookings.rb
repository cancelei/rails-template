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
FactoryBot.define do
  factory :booking do
    tour
    user factory: %i[user tourist]
    spots { 1 }
    status { :confirmed }
    booked_email { Faker::Internet.email }
    booked_name { Faker::Name.name }
    created_via { "user_portal" }
  end
end
