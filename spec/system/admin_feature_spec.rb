require "rails_helper"

RSpec.describe "Admin" do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:guide) { FactoryBot.create(:user, :guide) }
  let(:tourist) { FactoryBot.create(:user, :tourist) }

  describe "Admin metrics page" do
    context "when user is an admin" do
      before do
        sign_in admin
        visit admin_metrics_path
      end

      it_behaves_like "an accessible page"

      it "displays metrics dashboard" do
        expect(page).to have_text("Admin Dashboard")
      end
    end

    context "when user is not an admin" do
      before do
        sign_in tourist
        visit admin_metrics_path
      end

      it "redirects unauthorized users" do
        expect(page).to have_current_path(root_path, ignore_query: true)
        expect(page).to have_text("Access denied")
      end
    end

    context "when user is not signed in" do
      before do
        visit admin_metrics_path
      end

      it "redirects to sign in page" do
        expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      end
    end
  end
end
