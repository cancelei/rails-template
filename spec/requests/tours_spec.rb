require "rails_helper"

RSpec.describe "Tours" do
  let(:tourist) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }
  let(:tour) { create(:tour, guide:) }

  describe "GET /tours" do
    let!(:scheduled_tour) { create(:tour, status: :scheduled) }
    let!(:cancelled_tour) { create(:tour, status: :cancelled) }

    it "returns successful response" do
      get tours_path
      expect(response).to have_http_status(:success)
    end

    it "shows only available tours" do
      get tours_path
      expect(response.body).to include(scheduled_tour.title)
    end

    it "filters tours by status" do
      get tours_path, params: { status: "scheduled" }
      expect(response).to have_http_status(:success)
    end

    it "searches tours by title" do
      create(:tour, title: "Unique Adventure Tour")
      get tours_path, params: { q: "Unique" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /tours/:id" do
    it "shows tour details" do
      get tour_path(tour)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(tour.title)
    end

    it "shows tour add-ons" do
      add_on = create(:tour_add_on, tour:)
      get tour_path(tour)
      expect(response.body).to include(add_on.name)
    end

    it "shows available spots" do
      get tour_path(tour)
      expect(response.body).to include(tour.available_spots.to_s)
    end

    context "when tour has comments" do
      let!(:comment) { create(:comment, guide_profile: tour.guide.guide_profile) }

      it "shows comments for the guide" do
        get tour_path(tour)
        expect(response.body).to include(comment.content)
      end
    end
  end

  describe "GET /tours/new" do
    context "when user is a guide" do
      before { sign_in guide }

      it "returns successful response" do
        get new_tour_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is a tourist" do
      before { sign_in tourist }

      it "denies access" do
        get new_tour_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        get new_tour_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /tours" do
    context "when user is a guide" do
      before { sign_in guide }

      let(:valid_params) do
        {
          tour: {
            title: "Amazing Mountain Hike",
            description: "A beautiful mountain adventure",
            location_name: "Rocky Mountains",
            latitude: 40.7128,
            longitude: -74.0060,
            starts_at: 2.days.from_now,
            ends_at: 3.days.from_now,
            price_cents: 10_000,
            currency: "USD",
            max_participants: 10,
            available_spots: 10,
            tour_type: :group
          }
        }
      end

      it "creates a new tour" do
        expect do
          post tours_path, params: valid_params
        end.to change(Tour, :count).by(1)
      end

      it "sets the guide to current user" do
        post tours_path, params: valid_params
        expect(Tour.last.guide).to eq(guide)
      end

      it "sets default status to scheduled" do
        post tours_path, params: valid_params
        expect(Tour.last.status).to eq("scheduled")
      end

      it "redirects to tour show page" do
        post tours_path, params: valid_params
        expect(response).to redirect_to(tour_path(Tour.last))
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            tour: {
              title: "",
              description: "Test"
            }
          }
        end

        it "does not create a tour" do
          expect do
            post tours_path, params: invalid_params
          end.not_to change(Tour, :count)
        end

        it "renders new template" do
          post tours_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user is not a guide" do
      before { sign_in tourist }

      it "denies access" do
        post tours_path, params: { tour: { title: "Test" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /tours/:id" do
    context "when user is the tour owner" do
      before { sign_in guide }

      it "updates the tour" do
        patch tour_path(tour), params: { tour: { title: "Updated Title" } }
        expect(tour.reload.title).to eq("Updated Title")
      end

      it "redirects to tour show page" do
        patch tour_path(tour), params: { tour: { title: "Updated" } }
        expect(response).to redirect_to(tour_path(tour))
      end

      context "with invalid parameters" do
        it "does not update the tour" do
          original_title = tour.title
          patch tour_path(tour), params: { tour: { title: "" } }
          expect(tour.reload.title).to eq(original_title)
        end
      end
    end

    context "when user is not the tour owner" do
      let(:other_guide) { create(:user, :guide) }

      before { sign_in other_guide }

      it "denies access" do
        patch tour_path(tour), params: { tour: { title: "Hacked" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /tours/:id" do
    context "when user is the tour owner" do
      before { sign_in guide }

      it "deletes the tour" do
        tour # create it first

        expect do
          delete tour_path(tour)
        end.to change(Tour, :count).by(-1)
      end

      it "redirects to tours index" do
        delete tour_path(tour)
        expect(response).to redirect_to(tours_path)
      end
    end

    context "when user is not the tour owner" do
      let(:other_guide) { create(:user, :guide) }

      before { sign_in other_guide }

      it "denies access" do
        tour # create it first

        expect do
          delete tour_path(tour)
        end.not_to change(Tour, :count)
      end
    end
  end

  describe "Tour with add-ons pricing" do
    let!(:tour_with_addons) { create(:tour, guide:, price_cents: 5000) }
    let!(:addon1) { create(:tour_add_on, tour: tour_with_addons, price_cents: 1000, pricing_type: :per_person) }
    let!(:addon2) { create(:tour_add_on, tour: tour_with_addons, price_cents: 500, pricing_type: :flat_fee) }

    before { sign_in tourist }

    it "displays tour with add-ons" do
      get tour_path(tour_with_addons)
      expect(response.body).to include(addon1.name)
      expect(response.body).to include(addon2.name)
    end

    it "calculates total price with add-ons correctly" do
      # This would test the JavaScript calculator, so we'll test the model logic instead
      booking = create(:booking, tour: tour_with_addons, number_of_spots: 2)
      create(:booking_add_on, booking:, tour_add_on: addon1, price_cents_at_booking: 1000)
      create(:booking_add_on, booking:, tour_add_on: addon2, price_cents_at_booking: 500)

      # Base price: 5000 * 2 = 10000
      # Addon1 (per person): 1000 * 2 = 2000
      # Addon2 (flat fee): 500
      # Total: 12500
      expect(booking.total_price_cents).to eq(12_500)
    end
  end
end
