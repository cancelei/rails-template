require "rails_helper"

RSpec.describe "Bookings" do
  let(:tourist) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }
  let(:tour) { create(:tour, guide:, status: :scheduled, available_spots: 10) }

  describe "POST /tours/:tour_id/bookings" do
    context "when user is signed in as tourist" do
      before { sign_in tourist }

      context "with valid parameters" do
        let(:valid_params) do
          {
            booking: {
              spots: 2
            }
          }
        end

        it "creates a new booking" do
          expect do
            post tour_bookings_path(tour), params: valid_params
          end.to change(Booking, :count).by(1)
        end

        it "sets the booking user to current user" do
          post tour_bookings_path(tour), params: valid_params
          expect(Booking.last.user).to eq(tourist)
        end

        it "sets the booking tour" do
          post tour_bookings_path(tour), params: valid_params
          expect(Booking.last.tour).to eq(tour)
        end

        it "redirects to manage booking page" do
          post tour_bookings_path(tour), params: valid_params
          expect(response).to redirect_to(manage_booking_path(Booking.last, email: tourist.email))
        end

        it "shows success notice" do
          post tour_bookings_path(tour), params: valid_params
          follow_redirect!
          expect(response.body).to include("Booking was successful")
        end
      end

      context "with add-ons" do
        let!(:addon1) { create(:tour_add_on, tour:, active: true, price_cents: 1000) }
        let!(:addon2) { create(:tour_add_on, tour:, active: true, price_cents: 1500) }

        it "creates booking with selected add-ons" do
          params = {
            booking: { spots: 2 },
            add_on_ids: [addon1.id, addon2.id]
          }

          expect do
            post tour_bookings_path(tour), params:
          end.to change(Booking, :count).by(1)
                                        .and change(BookingAddOn, :count).by(2)
        end

        it "stores price at booking time" do
          params = {
            booking: { spots: 2 },
            add_on_ids: [addon1.id]
          }

          post(tour_bookings_path(tour), params:)
          booking_addon = Booking.last.booking_add_ons.first
          expect(booking_addon.price_cents_at_booking).to eq(1000)
        end

        it "only creates add-ons for active tour add-ons" do
          inactive_addon = create(:tour_add_on, tour:, active: false)

          params = {
            booking: { spots: 1 },
            add_on_ids: [addon1.id, inactive_addon.id]
          }

          post(tour_bookings_path(tour), params:)
          expect(Booking.last.booking_add_ons.count).to eq(1)
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            booking: {
              spots: 0
            }
          }
        end

        it "does not create a booking" do
          expect do
            post tour_bookings_path(tour), params: invalid_params
          end.not_to change(Booking, :count)
        end

        it "redirects back to tour" do
          post tour_bookings_path(tour), params: invalid_params
          expect(response).to redirect_to(tour)
        end

        it "shows error message" do
          post tour_bookings_path(tour), params: invalid_params
          follow_redirect!
          expect(response.body).to match(/error|invalid/i)
        end
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in page" do
        post tour_bookings_path(tour), params: { booking: { spots: 1 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /bookings/:id/manage" do
    let(:booking) { create(:booking, user: tourist, tour:) }

    context "when user is signed in and owns booking" do
      before { sign_in tourist }

      it "shows booking management page" do
        get manage_booking_path(booking, email: tourist.email)
        expect(response).to have_http_status(:success)
      end

      it "displays booking details" do
        get manage_booking_path(booking, email: tourist.email)
        expect(response.body).to include(tour.title)
      end
    end

    context "when accessing with magic link (email param)" do
      it "allows access without sign in" do
        get manage_booking_path(booking, email: booking.booked_email)
        expect(response).to have_http_status(:success)
      end

      it "shows booking details" do
        get manage_booking_path(booking, email: booking.booked_email)
        expect(response.body).to include(tour.title)
      end
    end

    context "when trying to access another user's booking" do
      let(:other_tourist) { create(:user, :tourist) }

      before { sign_in other_tourist }

      it "does not show the booking" do
        get manage_booking_path(booking, email: other_tourist.email)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /bookings/:id/cancel" do
    let(:booking) { create(:booking, user: tourist, tour:) }

    context "when user owns the booking" do
      before { sign_in tourist }

      it "cancels the booking" do
        post cancel_booking_path(booking, email: tourist.email)
        expect(booking.reload.status).to eq("cancelled")
      end

      it "shows success message" do
        post cancel_booking_path(booking, email: tourist.email)
        follow_redirect!
        expect(response.body).to include("cancelled")
      end

      it "sends cancellation email" do
        expect do
          post cancel_booking_path(booking, email: tourist.email)
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context "when accessing with magic link" do
      it "allows cancellation without sign in" do
        post cancel_booking_path(booking, email: booking.booked_email)
        expect(booking.reload.status).to eq("cancelled")
      end
    end
  end

  describe "POST /bookings/:id/review" do
    let(:booking) { create(:booking, user: tourist, tour:, status: :confirmed) }

    context "when user owns the booking" do
      before { sign_in tourist }

      let(:review_params) do
        {
          review: {
            rating: 5,
            comment: "Great tour!"
          },
          email: tourist.email
        }
      end

      it "creates a review" do
        expect do
          post review_booking_path(booking), params: review_params
        end.to change(Review, :count).by(1)
      end

      it "associates review with booking" do
        post review_booking_path(booking), params: review_params
        expect(Review.last.booking).to eq(booking)
      end

      it "associates review with user" do
        post review_booking_path(booking), params: review_params
        expect(Review.last.user).to eq(tourist)
      end

      it "redirects to manage page" do
        post review_booking_path(booking), params: review_params
        expect(response).to redirect_to(manage_booking_path(booking, email: tourist.email))
      end

      context "with invalid review" do
        let(:invalid_review_params) do
          {
            review: {
              rating: 0,
              comment: ""
            },
            email: tourist.email
          }
        end

        it "does not create review" do
          expect do
            post review_booking_path(booking), params: invalid_review_params
          end.not_to change(Review, :count)
        end

        it "shows error message" do
          post review_booking_path(booking), params: invalid_review_params
          follow_redirect!
          expect(response.body).to match(/error/i)
        end
      end
    end

    context "when accessing with magic link" do
      let(:review_params) do
        {
          review: {
            rating: 4,
            comment: "Good experience"
          },
          email: booking.booked_email
        }
      end

      it "allows review without sign in" do
        expect do
          post review_booking_path(booking), params: review_params
        end.to change(Review, :count).by(1)
      end
    end
  end

  describe "Authorization" do
    let(:booking) { create(:booking, user: tourist, tour:) }
    let(:other_tourist) { create(:user, :tourist) }

    before { sign_in other_tourist }

    it "prevents managing another user's booking" do
      get manage_booking_path(booking, email: other_tourist.email)
      expect(response).not_to have_http_status(:success)
    end

    it "prevents cancelling another user's booking" do
      post cancel_booking_path(booking, email: other_tourist.email)
      expect(booking.reload.status).not_to eq("cancelled")
    end

    it "prevents reviewing another user's booking" do
      expect do
        post review_booking_path(booking), params: {
          review: { rating: 5, comment: "Test" },
          email: other_tourist.email
        }
      end.not_to change(Review, :count)
    end
  end
end
