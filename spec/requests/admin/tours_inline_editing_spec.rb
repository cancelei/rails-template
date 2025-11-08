# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Tours Inline Editing" do
  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:tour) { create(:tour, guide:) }

  before do
    login_as admin, scope: :user
  end

  describe "GET /admin/tours/:id/edit (Turbo Stream)" do
    context "when requesting from tours index" do
      it "renders the inline edit form for tours index" do
        get edit_admin_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("turbo-stream")
        expect(response.body).to include("Edit Tour")
        expect(response.body).to include('action="replace"')
        expect(response.body).to include(tour.title)
      end
    end

    context "when requesting from guide profiles page" do
      it "renders the guide profile tour edit form" do
        get edit_admin_tour_path(tour),
            headers: {
              "Accept" => "text/vnd.turbo-stream.html",
              "Referer" => admin_guide_profile_path(guide.guide_profile)
            }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Edit Tour")
      end
    end

    context "as HTML" do
      it "renders the standard edit page" do
        get edit_admin_tour_path(tour)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Edit Tour")
        expect(response.body).to include(tour.title)
      end
    end
  end

  describe "GET /admin/tours/:id (Turbo Stream - Cancel)" do
    it "renders the tour display partial" do
      get admin_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("turbo-stream")
      expect(response.body).to include(tour.title)
      expect(response.body).to include('action="replace"')
    end
  end

  describe "PATCH /admin/tours/:id (Turbo Stream)" do
    let(:valid_attributes) do
      {
        title: "Updated Tour Title",
        description: "Updated description",
        capacity: 15,
        status: "scheduled"
      }
    end

    let(:invalid_attributes) do
      {
        title: "", # Title is required
        capacity: -1
      }
    end

    context "with valid attributes from tours index" do
      it "updates the tour and renders success turbo stream" do
        patch admin_tour_path(tour),
              params: { tour: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("turbo-stream")

        # Check that success response includes updated tour and notification
        expect(response.body).to include("Updated Tour Title")
        expect(response.body).to include("Tour updated successfully")
        expect(response.body).to include('target="notifications"')

        # Verify database update
        tour.reload
        expect(tour.title).to eq("Updated Tour Title")
        expect(tour.capacity).to eq(15)
      end
    end

    context "with valid attributes from guide profile page" do
      it "updates and renders guide profile context partial" do
        patch admin_tour_path(tour),
              params: { tour: valid_attributes },
              headers: {
                "Accept" => "text/vnd.turbo-stream.html",
                "Referer" => admin_guide_profile_path(guide.guide_profile)
              }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Updated Tour Title")
        expect(response.body).to include("Tour updated successfully")

        tour.reload
        expect(tour.title).to eq("Updated Tour Title")
      end
    end

    context "with invalid attributes" do
      it "re-renders the edit form with errors" do
        patch admin_tour_path(tour),
              params: { tour: invalid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Edit Tour")
        expect(response.body).to include("error")

        # Verify database was not updated
        tour.reload
        expect(tour.title).not_to eq("")
      end
    end

    context "as HTML" do
      it "redirects to tours index with notice" do
        patch admin_tour_path(tour), params: { tour: valid_attributes }

        expect(response).to redirect_to(admin_tours_path)
        expect(flash[:notice]).to include("successfully updated")

        tour.reload
        expect(tour.title).to eq("Updated Tour Title")
      end
    end
  end

  describe "permissions" do
    context "when not authenticated" do
      before { logout :user }

      it "redirects to sign in" do
        get edit_admin_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }
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
          get edit_admin_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "shared form rendering" do
    it "uses the shared tour inline edit form partial" do
      get edit_admin_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("Edit Tour")
      expect(response.body).to include("title")
      expect(response.body).to include("description")
      expect(response.body).to include("capacity")
      expect(response.body).to include("Save Changes")
      expect(response.body).to include("Cancel")
    end

    it "shows advanced fields for admin" do
      get edit_admin_tour_path(tour), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      # Admin should see currency and lat/long fields
      expect(response.body).to include("currency")
      expect(response.body).to include("latitude")
      expect(response.body).to include("longitude")
    end
  end

  describe "real-time updates" do
    it "broadcasts updates via Turbo Streams" do
      expect do
        patch admin_tour_path(tour),
              params: { tour: valid_attributes },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end.to have_broadcasted_to("admin_tours")
    end
  end
end
