# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Bookings Inline Editing" do
  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:) }
  let(:booking) { create(:booking, tour:, user: tourist) }

  before do
    login_as admin, scope: :user
  end

  describe "GET /admin/bookings/:id/edit (Turbo Stream)" do
    it "renders the inline edit form" do
      get edit_admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("turbo-stream")
      expect(response.body).to include("Edit Booking")
      expect(response.body).to include('action="replace"')
      expect(response.body).to include("Edit Booking")
      expect(response.body).to include(booking.tour.title)
      expect(response.body).to include(booking.user.name)
    end

    context "as HTML" do
      it "renders the standard edit page" do
        get edit_admin_booking_path(booking)

        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "GET /admin/bookings/:id (Turbo Stream - Cancel)" do
    it "renders the booking display partial" do
      get admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("turbo-stream")
      expect(response.body).to include(booking.tour.title)
      expect(response.body).to include(booking.user.name)
      expect(response.body).to include('action="replace"')
    end
  end

  describe "PATCH /admin/bookings/:id (Turbo Stream)" do
    let(:valid_attributes) do
      {
        status: "confirmed",
        notes: "Booking confirmed with special requirements"
      }
    end

    let(:invalid_attributes) do
      {
        status: "invalid_status"
      }
    end

    context "with valid attributes" do
      it "updates the booking and renders success turbo stream" do
        patch admin_booking_path(booking),
              params: { booking: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("turbo-stream")

        # Check that success response includes updated booking and notification
        expect(response.body).to include("Confirmed")
        expect(response.body).to include("Booking updated successfully")
        expect(response.body).to include('target="notifications"')

        # Verify database update
        booking.reload
        expect(booking.status).to eq("confirmed")
        expect(booking.notes).to eq("Booking confirmed with special requirements")
      end

      it "includes all booking information in response" do
        patch admin_booking_path(booking),
              params: { booking: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include(booking.tour.title)
        expect(response.body).to include(booking.user.name)
        expect(response.body).to include(booking.user.email)
      end
    end

    context "with invalid attributes" do
      it "re-renders the edit form with errors" do
        # Make booking invalid
        booking.update_column(:status, "confirmed")

        patch admin_booking_path(booking),
              params: { booking: { status: "" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Edit Booking")
        expect(response.body).to include("Edit Booking")

        # Verify database was not updated
        booking.reload
        expect(booking.status).to eq("confirmed")
      end
    end

    context "as HTML" do
      it "redirects to bookings index with notice" do
        patch admin_booking_path(booking), params: { booking: valid_attributes }

        expect(response).to redirect_to(admin_bookings_path)
        expect(flash[:notice]).to include("successfully updated")

        booking.reload
        expect(booking.status).to eq("confirmed")
      end
    end
  end

  describe "status change tracking" do
    it "updates status from pending to confirmed" do
      pending_booking = create(:booking, tour:, user: tourist, status: "pending")

      patch admin_booking_path(pending_booking),
            params: { booking: { status: "confirmed" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      pending_booking.reload
      expect(pending_booking.status).to eq("confirmed")
    end

    it "updates status to cancelled" do
      confirmed_booking = create(:booking, tour:, user: tourist, status: "confirmed")

      patch admin_booking_path(confirmed_booking),
            params: { booking: { status: "cancelled" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      confirmed_booking.reload
      expect(confirmed_booking.status).to eq("cancelled")
    end
  end

  describe "notes management" do
    it "allows adding notes to a booking" do
      patch admin_booking_path(booking),
            params: { booking: { notes: "Customer requested vegetarian meal" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      booking.reload
      expect(booking.notes).to eq("Customer requested vegetarian meal")
    end

    it "allows updating existing notes" do
      booking.update(notes: "Original note")

      patch admin_booking_path(booking),
            params: { booking: { notes: "Updated note with new information" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      booking.reload
      expect(booking.notes).to eq("Updated note with new information")
    end

    it "allows clearing notes" do
      booking.update(notes: "Some notes")

      patch admin_booking_path(booking),
            params: { booking: { notes: "" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      booking.reload
      expect(booking.notes).to be_blank
    end
  end

  describe "permissions" do
    context "when not authenticated" do
      before { logout :user }

      it "redirects to sign in" do
        get edit_admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as guide" do
      before do
        logout :user
        login_as guide, scope: :user
      end

      it "denies access", :raise_exceptions do
        expect do
          get edit_admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when authenticated as tourist" do
      before do
        logout :user
        login_as tourist, scope: :user
      end

      it "denies access", :raise_exceptions do
        expect do
          get edit_admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "form rendering" do
    it "includes all required form fields" do
      get edit_admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("Booking Status")
      expect(response.body).to include("Notes")
      expect(response.body).to include("Save Changes")
      expect(response.body).to include("Cancel")

      # Status options
      expect(response.body).to include("Pending")
      expect(response.body).to include("Confirmed")
      expect(response.body).to include("Completed")
      expect(response.body).to include("Cancelled")
    end

    it "displays booking context information" do
      get edit_admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include(booking.tour.title)
      expect(response.body).to include(booking.user.name)
    end
  end

  describe "turbo frame integration" do
    it "wraps form in correct turbo frame" do
      get edit_admin_booking_path(booking), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("turbo-frame")
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(booking))
    end

    it "targets the correct DOM element for replacement" do
      patch admin_booking_path(booking),
            params: { booking: valid_attributes },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      dom_id = ActionView::RecordIdentifier.dom_id(booking)
      expect(response.body).to include("target=\"#{dom_id}\"")
    end
  end
end
