# == Schema Information
#
# Table name: reviews
#
#  id         :bigint           not null, primary key
#  comment    :text
#  rating     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  booking_id :bigint           not null
#  tour_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_reviews_on_booking_id  (booking_id)
#  index_reviews_on_tour_id     (tour_id)
#  index_reviews_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (tour_id => tours.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :review do
    booking
    tour { booking.tour }
    user { booking.user }
    rating { rand(1..5) }
    comment { Faker::Lorem.paragraph(sentence_count: 2) }
  end
end
