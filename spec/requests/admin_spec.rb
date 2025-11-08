require "rails_helper"

RSpec.describe "Admin" do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }
  let!(:guides) { create_list(:user, 5, :guide) }
  let!(:tourists) { create_list(:user, 10, :tourist) }
  let!(:tours) { create_list(:tour, 15, guide:) }
  let!(:upcoming_tours) { create_list(:tour, 8, guide:, starts_at: 2.days.from_now, status: :scheduled) }
  let!(:recent_bookings) { create_list(:booking, 12, tour: tours.first, created_at: 3.days.ago) }

  describe "GET /admin/metrics" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get admin_metrics_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated but not an admin" do
      before { sign_in regular_user }

      it "raises authorization error" do
        expect do
          get admin_metrics_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_metrics_path
        expect(response).to have_http_status(:success)
      end

      it "calculates guide count correctly" do
        get admin_metrics_path
        # Includes admin, guide, and 5 guides created in setup
        expect(assigns(:guide_count)).to be >= 6
      end

      it "calculates tourist count correctly" do
        get admin_metrics_path
        # Includes regular_user and 10 tourists created in setup
        expect(assigns(:tourist_count)).to be >= 11
      end

      it "calculates tour count correctly" do
        get admin_metrics_path
        expect(assigns(:tour_count)).to be >= 23 # 15 + 8 from setup
      end

      it "calculates upcoming tour count correctly" do
        get admin_metrics_path
        expect(assigns(:upcoming_tour_count)).to be >= 8
      end

      it "calculates bookings in last 7 days" do
        get admin_metrics_path
        expect(assigns(:booking_count_7_days)).to be >= 12
      end

      it "calculates bookings in last 30 days" do
        get admin_metrics_path
        expect(assigns(:booking_count_30_days)).to be >= 12
      end

      it "loads recent bookings" do
        get admin_metrics_path
        expect(assigns(:recent_bookings).count).to be <= 10
      end
    end
  end
end
