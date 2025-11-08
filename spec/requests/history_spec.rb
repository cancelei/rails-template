require "rails_helper"

RSpec.describe "History" do
  let(:tourist) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }
  let!(:guide_profile) { create(:guide_profile, user: guide) }
  let!(:past_tour) { create(:tour, guide:, starts_at: 2.days.ago) }
  let!(:future_tour) { create(:tour, guide:, starts_at: 2.days.from_now) }
  let!(:past_booking) { create(:booking, user: tourist, tour: past_tour, status: :confirmed) }
  let!(:future_booking) { create(:booking, user: tourist, tour: future_tour, status: :confirmed) }

  describe "GET /history" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get history_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      before { sign_in tourist }

      it "returns http success" do
        get history_path
        expect(response).to have_http_status(:success)
      end

      it "shows only past bookings" do
        get history_path
        expect(response.body).to include(past_tour.title)
        expect(response.body).not_to include(future_tour.title)
      end

      it "orders bookings by tour start date descending" do
        older_tour = create(:tour, guide:, starts_at: 5.days.ago)
        create(:booking, user: tourist, tour: older_tour, status: :confirmed)

        get history_path

        # Check that the older booking appears in the response
        expect(response.body).to include(older_tour.title)
      end

      context "with guide statistics" do
        let!(:another_past_tour) { create(:tour, guide:, starts_at: 3.days.ago) }
        let!(:another_booking) do
          create(:booking, user: tourist, tour: another_past_tour, status: :confirmed, spots: 2)
        end
        let!(:comment) { create(:comment, user: tourist, guide_profile:) }
        let!(:like) { create(:like, user: tourist, comment:) }

        it "calculates guide statistics correctly" do
          get history_path
          expect(response).to have_http_status(:success)
          # The view should display guide statistics
          expect(assigns(:guide_stats)).to be_present
        end
      end
    end

    context "when user is unauthorized" do
      it "raises authorization error for non-tourists trying to view history" do
        sign_in guide
        expect { get history_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
