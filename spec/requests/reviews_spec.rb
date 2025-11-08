require "rails_helper"

RSpec.describe "Reviews" do
  let(:tourist) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }
  let(:tour) { create(:tour, guide:) }
  let(:confirmed_booking) { create(:booking, user: tourist, tour:, status: :confirmed) }

  describe "Creating reviews" do
    before { sign_in tourist }

    context "when tourist has confirmed booking" do
      before { confirmed_booking }

      let(:valid_params) do
        {
          review: {
            booking_id: confirmed_booking.id,
            rating: 5,
            comment: "Amazing tour! The guide was very knowledgeable."
          }
        }
      end

      it "creates a new review" do
        expect do
          post reviews_path, params: valid_params
        end.to change(Review, :count).by(1)
      end

      it "associates review with the booking" do
        post reviews_path, params: valid_params
        expect(Review.last.booking).to eq(confirmed_booking)
      end

      it "associates review with the tourist" do
        post reviews_path, params: valid_params
        expect(Review.last.user).to eq(tourist)
      end

      it "redirects after creation" do
        post reviews_path, params: valid_params
        expect(response).to have_http_status(:redirect)
      end

      context "with invalid rating" do
        it "requires rating between 1 and 5" do
          invalid_params = {
            review: {
              booking_id: confirmed_booking.id,
              rating: 6,
              comment: "Test"
            }
          }

          expect do
            post reviews_path, params: invalid_params
          end.not_to change(Review, :count)
        end
      end

      context "when review already exists for booking" do
        let!(:existing_review) { create(:review, booking: confirmed_booking, user: tourist) }

        it "does not create duplicate review" do
          expect do
            post reviews_path, params: valid_params
          end.not_to change(Review, :count)
        end
      end
    end

    context "when tourist does not have confirmed booking" do
      it "denies creating review" do
        pending_booking = create(:booking, user: tourist, tour:, status: :pending)

        review_params = {
          review: {
            booking_id: pending_booking.id,
            rating: 5,
            comment: "Test"
          }
        }

        expect do
          post reviews_path, params: review_params
        end.not_to change(Review, :count)
      end
    end
  end

  describe "Viewing reviews" do
    let!(:review1) { create(:review, booking: confirmed_booking, rating: 5) }
    let!(:review2) { create(:review, rating: 4) }

    it "shows reviews on guide profile" do
      get guide_profile_path(guide.guide_profile)
      expect(response.body).to include(review1.comment)
    end

    it "displays review rating" do
      get guide_profile_path(guide.guide_profile)
      expect(response.body).to include("5")
    end

    it "shows reviewer name" do
      get guide_profile_path(guide.guide_profile)
      expect(response.body).to include(tourist.name)
    end
  end

  describe "Admin management" do
    let(:admin) { create(:user, :admin) }
    let!(:review) { create(:review, booking: confirmed_booking) }

    before { sign_in admin }

    it "allows admin to view all reviews" do
      get admin_reviews_path
      expect(response).to have_http_status(:success)
    end

    it "allows admin to delete inappropriate reviews" do
      expect do
        delete admin_review_path(review)
      end.to change(Review, :count).by(-1)
    end

    it "filters reviews by rating" do
      create(:review, rating: 5)
      create(:review, rating: 2)

      get admin_reviews_path, params: { rating: 5 }
      expect(response).to have_http_status(:success)
    end
  end

  describe "Review statistics" do
    let(:guide_with_reviews) { create(:user, :guide) }
    let(:tour1) { create(:tour, guide: guide_with_reviews) }
    let(:tour2) { create(:tour, guide: guide_with_reviews) }

    before do
      # Create bookings and reviews
      booking1 = create(:booking, tour: tour1, status: :confirmed)
      booking2 = create(:booking, tour: tour2, status: :confirmed)

      create(:review, booking: booking1, rating: 5)
      create(:review, booking: booking2, rating: 4)
    end

    it "calculates average rating" do
      reviews = Review.joins(booking: :tour).where(tours: { guide_id: guide_with_reviews.id })
      average = reviews.average(:rating)

      expect(average).to eq(4.5)
    end

    it "counts total reviews" do
      reviews = Review.joins(booking: :tour).where(tours: { guide_id: guide_with_reviews.id })
      expect(reviews.count).to eq(2)
    end
  end

  describe "Review permissions" do
    let(:other_tourist) { create(:user, :tourist) }
    let!(:review) { create(:review, booking: confirmed_booking, user: tourist) }

    context "when trying to edit own review" do
      before { sign_in tourist }

      it "allows editing" do
        patch review_path(review), params: { review: { rating: 4 } }
        expect(review.reload.rating).to eq(4)
      end
    end

    context "when trying to edit another user's review" do
      before { sign_in other_tourist }

      it "denies access" do
        patch review_path(review), params: { review: { rating: 1 } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when trying to delete own review" do
      before { sign_in tourist }

      it "allows deletion" do
        expect do
          delete review_path(review)
        end.to change(Review, :count).by(-1)
      end
    end
  end
end
