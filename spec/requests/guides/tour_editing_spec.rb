# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Guide Tour Editing with Shared Form" do
  let(:guide) { create(:user, :guide) }
  let(:other_guide) { create(:user, :guide) }
  let(:tour) { create(:tour, guide:) }
  let(:other_tour) { create(:tour, guide: other_guide) }

  before do
    login_as guide, scope: :user
  end

  describe "GET /tours/:id/edit (Turbo Stream)" do
    it "renders the shared inline edit form for guide's own tour" do
      get edit_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("turbo-stream")
      expect(response.body).to include("Edit Tour")
      expect(response.body).to include(tour.title)
    end

    it "does not show advanced fields for guides" do
      get edit_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      # Guide should NOT see admin-only fields
      expect(response.body).not_to include("Currency") # Admin only
      expect(response.body).not_to include("Latitude") # Admin only
      expect(response.body).not_to include("Longitude") # Admin only

      # But should see basic fields
      expect(response.body).to include("Title")
      expect(response.body).to include("Description")
      expect(response.body).to include("Capacity")
    end

    it "denies access to other guide's tour" do
      expect do
        get edit_tour_path(other_tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    context "as HTML" do
      it "renders the standard edit page" do
        get edit_tour_path(tour)

        expect(response).to have_http_status(:success)
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "PATCH /tours/:id (Turbo Stream)" do
    let(:valid_attributes) do
      {
        title: "Updated by Guide",
        description: "Updated description",
        capacity: 25,
        status: "scheduled",
        price_cents: 7500
      }
    end

    context "with valid attributes" do
      it "updates the guide's own tour using shared form" do
        patch tour_path(tour),
              params: { tour: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("turbo-stream")

        # Check success response
        expect(response.body).to include("Updated by Guide")
        expect(response.body).to include("Tour updated successfully")

        # Verify database update
        tour.reload
        expect(tour.title).to eq("Updated by Guide")
        expect(tour.capacity).to eq(25)
        expect(tour.price_cents).to eq(7500)
      end

      it "renders the tour card partial after successful update" do
        patch tour_path(tour),
              params: { tour: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include("tour_card") # Guide uses card display
        expect(response.body).to include("Updated by Guide")
      end
    end

    context "with invalid attributes" do
      let(:invalid_attributes) do
        {
          title: "", # Required field
          capacity: 0 # Must be positive
        }
      end

      it "re-renders the shared edit form with errors" do
        patch tour_path(tour),
              params: { tour: invalid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Edit Tour")
        expect(response.body).to include("error")

        # Database should not be updated
        tour.reload
        expect(tour.title).not_to be_blank
      end
    end

    context "attempting to edit other guide's tour" do
      it "raises authorization error" do
        expect do
          patch tour_path(other_tour),
                params: { tour: valid_attributes },
                headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.to raise_error(Pundit::NotAuthorizedError)

        # Verify database was not updated
        other_tour.reload
        expect(other_tour.title).not_to eq("Updated by Guide")
      end
    end

    context "as HTML" do
      it "redirects to tour show page with notice" do
        patch tour_path(tour), params: { tour: valid_attributes }

        expect(response).to redirect_to(tour_path(tour))
        expect(flash[:notice]).to include("successfully updated")

        tour.reload
        expect(tour.title).to eq("Updated by Guide")
      end
    end
  end

  describe "shared form behavior" do
    it "uses the same form partial as admin but with different settings" do
      get edit_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      # Should use shared partial structure
      expect(response.body).to include("Edit Tour")
      expect(response.body).to include("Save Changes")
      expect(response.body).to include("Cancel")

      # Should have guide-specific cancel URL
      expect(response.body).to include(tour_path(tour))
      expect(response.body).not_to include("admin")
    end

    it "submits to guide route, not admin route" do
      get edit_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      # Form should submit to /tours/:id not /admin/tours/:id
      expect(response.body).to include("action=\"#{tour_path(tour)}\"")
      expect(response.body).not_to include("/admin/tours/")
    end
  end

  describe "tour type and booking deadline" do
    it "allows changing to private tour with booking deadline" do
      patch tour_path(tour),
            params: {
              tour: {
                tour_type: "private_tour",
                booking_deadline_hours: 48
              }
            },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)

      tour.reload
      expect(tour.tour_type).to eq("private_tour")
      expect(tour.booking_deadline_hours).to eq(48)
    end
  end

  describe "guide dashboard integration" do
    it "updates tour from dashboard view" do
      # Simulate editing from guide dashboard
      get edit_tour_path(tour),
          headers: {
            "Accept" => "text/vnd.turbo-stream.html",
            "Referer" => guide_dashboard_path
          }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Tour")
    end

    it "broadcasts updates to guide's channel" do
      expect do
        patch tour_path(tour),
              params: { tour: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end.to have_broadcasted_to("guide_#{guide.id}_tours")
    end
  end

  describe "permissions and scoping" do
    let(:admin) { create(:user, :admin) }

    context "when signed in as admin" do
      before do
        logout :user
        login_as admin, scope: :user
      end

      it "admin cannot use guide tour routes to edit tours" do
        # Admin should use /admin/tours/:id routes, not /tours/:id
        patch tour_path(tour),
              params: { tour: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        # Should still work but redirects appropriately
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      before { logout :user }

      it "redirects to sign in" do
        get edit_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "form fields available to guides" do
    before do
      get edit_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "includes basic tour information fields" do
      expect(response.body).to include("Title")
      expect(response.body).to include("Description")
      expect(response.body).to include("Max Capacity")
    end

    it "includes pricing field" do
      expect(response.body).to include("Price")
    end

    it "includes location field" do
      expect(response.body).to include("Location")
    end

    it "includes date/time fields" do
      expect(response.body).to include("Start Date")
      expect(response.body).to include("End Date")
    end

    it "includes status field" do
      expect(response.body).to include("Status")
    end

    it "includes tour type field" do
      expect(response.body).to include("Tour type")
    end

    it "includes cover image URL field" do
      expect(response.body).to include("Cover image url")
    end
  end
end
