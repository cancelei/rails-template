require "rails_helper"

RSpec.describe "Admin::Bookings" do
  let(:admin) { create(:user, :admin) }
  let(:tourist) { create(:user, :tourist) }
  let(:guide) { create(:user, :guide) }
  let(:tour) { create(:tour, guide:) }
  let!(:booking) { create(:booking, tour:, user: tourist) }

  describe "GET /admin/bookings" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get admin_bookings_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { sign_in tourist }

      it "raises authorization error", :raise_exceptions do
        expect do
          get admin_bookings_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_bookings_path
        expect(response).to have_http_status(:success)
      end

      it "displays bookings" do
        get admin_bookings_path
        expect(assigns(:bookings)).to include(booking)
      end

      it "paginates bookings" do
        create_list(:booking, 30, tour:, user: tourist)
        get admin_bookings_path
        expect(assigns(:bookings).count).to eq(25)
      end

      it "filters by status" do
        confirmed_booking = create(:booking, tour:, status: :confirmed)
        cancelled_booking = create(:booking, tour:, status: :cancelled)

        get admin_bookings_path, params: { status: :confirmed }
        expect(assigns(:bookings)).to include(confirmed_booking)
        expect(assigns(:bookings)).not_to include(cancelled_booking)
      end
    end
  end

  describe "GET /admin/bookings/:id" do
    before { sign_in admin }

    it "returns http success" do
      get admin_booking_path(booking)
      expect(response).to have_http_status(:success)
    end

    it "displays booking details" do
      get admin_booking_path(booking)
      expect(response.body).to include(tour.title)
    end
  end

  describe "GET /admin/bookings/:id/edit" do
    before { sign_in admin }

    it "returns http success" do
      get edit_admin_booking_path(booking)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/bookings/:id" do
    before { sign_in admin }

    context "with valid parameters" do
      it "updates the booking" do
        patch admin_booking_path(booking), params: { booking: { status: :cancelled } }
        expect(booking.reload.status).to eq("cancelled")
      end

      it "redirects to bookings index" do
        patch admin_booking_path(booking), params: { booking: { status: :cancelled } }
        expect(response).to redirect_to(admin_bookings_path)
      end
    end

    context "with invalid parameters" do
      it "does not update the booking" do
        patch admin_booking_path(booking), params: { booking: { status: :invalid } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/bookings/:id" do
    before { sign_in admin }

    it "deletes the booking" do
      expect do
        delete admin_booking_path(booking)
      end.to change(Booking, :count).by(-1)
    end

    it "redirects to bookings index" do
      delete admin_booking_path(booking)
      expect(response).to redirect_to(admin_bookings_path)
    end
  end
end
