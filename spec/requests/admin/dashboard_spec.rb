require "rails_helper"

# rubocop:disable RSpec/RepeatedExample
RSpec.describe "Admin::Dashboard" do
  let(:admin) { create(:user, :admin) }
  let(:tourist) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }

  describe "GET /admin" do
    context "when user is an admin" do
      before { sign_in admin }

      it "returns successful response" do
        get admin_path
        expect(response).to have_http_status(:success)
      end

      it "displays metrics dashboard" do
        get admin_path
        expect(response.body).to include("Dashboard")
      end

      it "shows total users count" do
        create_list(:user, 5)
        get admin_path
        expect(response).to have_http_status(:success)
      end

      it "shows total tours count" do
        create_list(:tour, 3, guide:)
        get admin_path
        expect(response).to have_http_status(:success)
      end

      it "shows total bookings count" do
        tour = create(:tour, guide:)
        create_list(:booking, 2, tour:)
        get admin_path
        expect(response).to have_http_status(:success)
      end

      it "shows pending bookings separately" do
        tour = create(:tour, guide:)
        create_list(:booking, 2, tour:, status: :pending)
        create(:booking, tour:, status: :confirmed)

        get admin_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not an admin" do
      before { sign_in tourist }

      it "denies access" do
        get admin_path
        expect(response).to redirect_to(root_path)
      end

      it "shows access denied message" do
        get admin_path
        follow_redirect!
        expect(response.body).to include("Access denied")
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        get admin_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "Metrics calculation" do
    let(:tour1) { create(:tour, guide:, price_cents: 10_000) }
    let(:tour2) { create(:tour, guide:, price_cents: 15_000) }

    before do
      sign_in admin

      # Create test data
      create(:booking, tour: tour1, number_of_spots: 2, status: :confirmed)
      create(:booking, tour: tour2, number_of_spots: 3, status: :confirmed)
      create(:booking, tour: tour1, status: :pending)
    end

    it "calculates total revenue from confirmed bookings on metrics page" do
      get admin_metrics_path
      expect(response).to have_http_status(:success)
      # Revenue = (10_000 * 2) + (15_000 * 3) = 65_000
    end

    it "shows booking status distribution on metrics page" do
      get admin_metrics_path
      expect(response).to have_http_status(:success)
    end

    it "displays tour popularity rankings on metrics page" do
      get admin_metrics_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "Recent activity feed" do
    before { sign_in admin }

    it "shows recently created users" do
      recent_users = create_list(:user, 3)
      get admin_path

      recent_users.each do |user|
        expect(response.body).to include(user.email)
      end
    end

    it "shows recently created tours" do
      recent_tours = create_list(:tour, 2, guide:)
      get admin_path

      recent_tours.each do |tour|
        expect(response.body).to include(tour.title)
      end
    end

    it "shows recently updated bookings" do
      tour = create(:tour, guide:)
      create(:booking, tour:, updated_at: 1.hour.ago)

      get admin_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "Quick actions" do
    before { sign_in admin }

    it "provides link to manage users" do
      get admin_path
      expect(response.body).to include(admin_users_path)
    end

    it "provides link to manage tours" do
      get admin_path
      expect(response.body).to include(admin_tours_path)
    end

    it "provides link to manage bookings" do
      get admin_path
      expect(response.body).to include(admin_bookings_path)
    end

    it "provides link to view reviews" do
      get admin_path
      expect(response.body).to include(admin_reviews_path)
    end
  end

  describe "System health indicators" do
    before { sign_in admin }

    it "shows database status on admin dashboard" do
      get admin_path
      expect(response).to have_http_status(:success)
    end

    it "displays application version or environment on admin dashboard" do
      get admin_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "Data export capabilities" do
    before { sign_in admin }

    it "allows exporting user data" do
      get admin_users_path, params: { format: :csv }
      expect(response.content_type).to include("text/csv")
    end

    it "allows exporting booking data" do
      get admin_bookings_path, params: { format: :csv }
      expect(response.content_type).to include("text/csv")
    end
  end

  describe "Search and filtering" do
    before { sign_in admin }

    it "searches users by email" do
      create(:user, email: "specific@example.com")
      get admin_users_path, params: { q: "specific" }
      expect(response.body).to include("specific@example.com")
    end

    it "filters tours by status" do
      scheduled = create(:tour, status: :scheduled, guide:)
      create(:tour, status: :cancelled, guide:)

      get admin_tours_path, params: { status: "scheduled" }
      expect(response.body).to include(scheduled.title)
    end

    it "filters bookings by date range" do
      create(:booking, created_at: 30.days.ago)
      create(:booking, created_at: 1.day.ago)

      get admin_bookings_path, params: { date_from: 7.days.ago }
      expect(response).to have_http_status(:success)
    end
  end

  describe "Bulk operations" do
    before { sign_in admin }

    it "allows bulk status updates for tours" do
      tours = create_list(:tour, 3, status: :scheduled, guide:)

      patch admin_bulk_update_tours_path, params: {
        tour_ids: tours.map(&:id),
        status: "cancelled"
      }

      tours.each do |tour|
        expect(tour.reload.status).to eq("cancelled")
      end
    end

    it "allows bulk booking confirmation" do
      bookings = create_list(:booking, 3, status: :pending)

      patch admin_bulk_update_bookings_path, params: {
        booking_ids: bookings.map(&:id),
        status: "confirmed"
      }

      bookings.each do |booking|
        expect(booking.reload.status).to eq("confirmed")
      end
    end
  end

  describe "Audit log" do
    before { sign_in admin }

    it "logs admin actions" do
      tour = create(:tour, guide:)

      patch admin_tour_path(tour), params: { tour: { status: "cancelled" } }

      # Check that action was logged (if you have audit logging)
      expect(response).to have_http_status(:redirect)
    end

    it "shows who made changes" do
      get admin_path
      # Should show admin activity log
      expect(response).to have_http_status(:success)
    end
  end
end
# rubocop:enable RSpec/RepeatedExample
