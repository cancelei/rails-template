require "rails_helper"

RSpec.describe "Admin::WeatherSnapshots" do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }
  let!(:tours) { create_list(:tour, 3, guide:) }
  let!(:weather_snapshots) do
    tours.map { |tour| create(:weather_snapshot, tour:) }
  end

  describe "GET /admin/weather_snapshots" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get admin_weather_snapshots_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated but not an admin" do
      before { sign_in regular_user }

      it "raises authorization error", :raise_exceptions do
        expect do
          get admin_weather_snapshots_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_weather_snapshots_path
        expect(response).to have_http_status(:success)
      end

      it "loads weather snapshots with associated tours" do
        get admin_weather_snapshots_path
        expect(assigns(:weather_snapshots)).to be_present
        expect(assigns(:weather_snapshots).first.tour).to be_present
      end

      it "orders weather snapshots by created_at descending" do
        get admin_weather_snapshots_path
        snapshots = assigns(:weather_snapshots)
        expect(snapshots.first.created_at).to be >= snapshots.last.created_at
      end

      it "paginates weather snapshots with 25 per page" do
        create_list(:weather_snapshot, 30, tour: tours.first)
        get admin_weather_snapshots_path
        expect(assigns(:weather_snapshots).count).to be <= 25
      end
    end
  end
end
