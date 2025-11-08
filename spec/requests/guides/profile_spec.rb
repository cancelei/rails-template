require "rails_helper"

RSpec.describe "Guides::Profile" do
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let!(:guide_profile) { create(:guide_profile, user: guide) }

  describe "PATCH /guides/profile" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        patch guides_profile_path, params: { guide_profile: { bio: "New bio" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a tourist" do
      before { sign_in tourist }

      it "redirects to root with alert" do
        patch guides_profile_path, params: { guide_profile: { bio: "New bio" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Only tour guides can access this page")
      end
    end

    context "when user is a guide" do
      before { sign_in guide }

      context "with valid parameters" do
        let(:valid_params) do
          {
            guide_profile: {
              bio: "Experienced tour guide",
              languages: "English, French, German",
              years_of_experience: 10,
              certifications: "Licensed Tour Guide"
            }
          }
        end

        it "updates the guide profile" do
          patch guides_profile_path, params: valid_params
          guide_profile.reload
          expect(guide_profile.bio).to eq("Experienced tour guide")
          expect(guide_profile.languages).to eq("English, French, German")
          expect(guide_profile.years_of_experience).to eq(10)
          expect(guide_profile.certifications).to eq("Licensed Tour Guide")
        end

        it "redirects to dashboard with notice" do
          patch guides_profile_path, params: valid_params
          expect(response).to redirect_to(guide_dashboard_path)
          expect(flash[:notice]).to eq("Profile updated successfully")
        end

        context "with turbo stream request" do
          it "responds with turbo stream" do
            patch guides_profile_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
            expect(response.media_type).to eq("text/vnd.turbo-stream.html")
            expect(response.body).to include("guide_profile")
          end
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          { guide_profile: { years_of_experience: -5 } }
        end

        it "does not update the guide profile" do
          original_experience = guide_profile.years_of_experience
          patch guides_profile_path, params: invalid_params
          guide_profile.reload
          expect(guide_profile.years_of_experience).to eq(original_experience)
        end

        it "redirects to dashboard with alert" do
          patch guides_profile_path, params: invalid_params
          expect(response).to redirect_to(guide_dashboard_path)
          expect(flash[:alert]).to eq("Failed to update profile")
        end

        context "with turbo stream request" do
          it "responds with unprocessable entity status" do
            patch guides_profile_path, params: invalid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      it "creates guide profile if not present" do
        guide_without_profile = create(:user, :guide)
        sign_in guide_without_profile

        expect do
          patch guides_profile_path, params: { guide_profile: { bio: "New guide" } }
        end.to change(GuideProfile, :count).by(1)
      end
    end
  end
end
