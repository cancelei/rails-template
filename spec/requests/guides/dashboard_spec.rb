require "rails_helper"

RSpec.describe "Guides::Dashboard" do
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let!(:guide_profile) { create(:guide_profile, user: guide) }
  let!(:upcoming_tour) { create(:tour, guide:, starts_at: 2.days.from_now) }
  let!(:past_tour) { create(:tour, guide:, starts_at: 2.days.ago) }
  let!(:comment) { create(:comment, guide_profile:, user: tourist) }

  describe "GET /guide/dashboard" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get guide_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a tourist" do
      before { sign_in tourist }

      it "redirects to root with alert" do
        get guide_dashboard_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Only tour guides can access this page")
      end
    end

    context "when user is a guide" do
      before { sign_in guide }

      it "returns http success" do
        get guide_dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "loads upcoming and past tours" do
        get guide_dashboard_path
        expect(assigns(:upcoming_tours)).to include(upcoming_tour)
        expect(assigns(:past_tours)).to include(past_tour)
      end

      it "loads reviews" do
        get guide_dashboard_path
        expect(assigns(:reviews)).to include(comment)
      end

      it "creates guide profile if not present" do
        guide_without_profile = create(:user, :guide)
        sign_in guide_without_profile

        expect do
          get guide_dashboard_path
        end.to change(GuideProfile, :count).by(1)
      end
    end
  end

  describe "GET /guide/dashboard/edit" do
    before { sign_in guide }

    it "returns http success" do
      get edit_guide_dashboard_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /guide/dashboard" do
    before { sign_in guide }

    context "with valid parameters" do
      let(:valid_params) do
        { guide_profile: { bio: "Updated bio", languages: "English, Spanish", years_of_experience: 5 } }
      end

      it "updates the guide profile" do
        patch guide_dashboard_path, params: valid_params
        guide_profile.reload
        expect(guide_profile.bio).to eq("Updated bio")
        expect(guide_profile.languages).to eq("English, Spanish")
        expect(guide_profile.years_of_experience).to eq(5)
      end

      it "redirects to dashboard with notice" do
        patch guide_dashboard_path, params: valid_params
        expect(response).to redirect_to(guide_dashboard_path)
        expect(flash[:notice]).to eq("Profile updated successfully")
      end

      context "with turbo stream request" do
        it "responds with turbo stream" do
          patch guide_dashboard_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          expect(response.body).to include("guide_profile")
        end
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        { guide_profile: { years_of_experience: -1 } }
      end

      it "does not update the guide profile" do
        original_bio = guide_profile.bio
        patch guide_dashboard_path, params: invalid_params
        guide_profile.reload
        expect(guide_profile.bio).to eq(original_bio)
      end

      it "renders edit template" do
        patch guide_dashboard_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
