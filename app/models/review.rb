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
class Review < ApplicationRecord
  belongs_to :booking
  belongs_to :tour
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 0..5 }
  validates :comment, length: { maximum: 1000 }, allow_blank: true
  validate :tour_is_done
  validate :one_review_per_booking

  def tour_is_done
    return unless tour && !tour.done?

    errors.add(:tour, "must be done to review")
  end

  def one_review_per_booking
    return unless booking && booking.review.present? && booking.review != self

    errors.add(:booking, "already has a review")
  end
end
