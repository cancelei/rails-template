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
require "rails_helper"

RSpec.describe Review do
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:, status: :done) }
  let(:booking) { create(:booking, tour:, user: tourist) }
  let(:review) { build(:review, booking:, tour:, user: tourist, rating: 5) }

  describe "associations" do
    it { is_expected.to belong_to(:booking) }
    it { is_expected.to belong_to(:tour) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { review }

    it { is_expected.to validate_presence_of(:rating) }
    it { is_expected.to validate_inclusion_of(:rating).in_range(0..5) }
    it { is_expected.to validate_length_of(:comment).is_at_most(1000) }

    it "allows blank comment" do
      review.comment = nil
      expect(review).to be_valid
    end

    it "allows empty comment" do
      review.comment = ""
      expect(review).to be_valid
    end

    it "is invalid with rating below 0" do
      review.rating = -1
      expect(review).not_to be_valid
    end

    it "is invalid with rating above 5" do
      review.rating = 6
      expect(review).not_to be_valid
    end

    it "accepts all valid ratings" do
      (0..5).each do |rating|
        review.rating = rating
        expect(review).to be_valid
      end
    end

    it "is invalid with comment too long" do
      review.comment = "a" * 1001
      expect(review).not_to be_valid
      expect(review.errors[:comment]).to be_present
    end
  end

  describe "custom validations" do
    describe "#tour_is_done" do
      it "is valid when tour is done" do
        tour.update(status: :done)
        expect(review).to be_valid
      end

      it "is invalid when tour is scheduled" do
        tour.update(status: :scheduled)
        expect(review).not_to be_valid
        expect(review.errors[:tour]).to include("must be done to review")
      end

      it "is invalid when tour is ongoing" do
        tour.update(status: :ongoing)
        expect(review).not_to be_valid
      end

      it "is invalid when tour is cancelled" do
        tour.update(status: :cancelled)
        expect(review).not_to be_valid
      end
    end

    describe "#one_review_per_booking" do
      it "allows first review for booking" do
        expect(review).to be_valid
      end

      it "prevents second review for same booking" do
        review.save!
        second_review = build(:review, booking:, tour:, user: tourist)
        expect(second_review).not_to be_valid
        expect(second_review.errors[:booking]).to include("already has a review")
      end

      it "allows different bookings to have reviews" do
        review.save!
        other_booking = create(:booking, tour:, user: create(:user, :tourist))
        other_review = build(:review, booking: other_booking, tour:, user: other_booking.user)
        expect(other_review).to be_valid
      end
    end
  end
end
