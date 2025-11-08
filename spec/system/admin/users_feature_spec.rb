require "rails_helper"

RSpec.describe "Admin Users Management" do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:guide) { FactoryBot.create(:user, :guide) }
  let(:tourist) { FactoryBot.create(:user, :tourist) }

  before do
    sign_in admin
  end

  describe "Users index page" do
    before do
      guide
      tourist
      visit admin_users_path
    end

    it "displays all users" do
      expect(page).to have_text("Users")
      expect(page).to have_text(guide.name)
      expect(page).to have_text(tourist.name)
    end

    it "allows searching users" do
      fill_in "q", with: guide.name
      # Wait for debounced search
      sleep 0.4

      expect(page).to have_text(guide.name)
      expect(page).to have_no_text(tourist.name)
    end

    it "allows creating new users", :uses_javascript do
      click_link "New User"

      # Modal should appear
      within "#modal" do
        fill_in "Name", with: "New Test User"
        fill_in "Email", with: "newuser@example.com"
        select "Tourist", from: "Role"
        fill_in "Password", with: "testpassword1234"
        fill_in "Password confirmation", with: "testpassword1234"

        click_button "Create User"
      end

      # Should see success notification
      expect(page).to have_text("User created successfully")
      expect(page).to have_text("New Test User")
    end

    it "allows editing users", :uses_javascript do
      click_link "Edit", match: :first

      within "#modal" do
        fill_in "Name", with: "Updated Name"
        click_button "Update User"
      end

      expect(page).to have_text("User updated successfully")
      expect(page).to have_text("Updated Name")
    end

    it "allows deleting users" do
      accept_confirm do
        click_button "Delete", match: :first
      end

      expect(page).to have_no_text(guide.name)
    end
  end

  describe "Access control" do
    context "when user is not an admin" do
      before do
        sign_out admin
        sign_in tourist
        visit admin_users_path
      end

      it "redirects to root path" do
        expect(page).to have_current_path(root_path)
        expect(page).to have_text("Access denied")
      end
    end

    context "when user is not signed in" do
      before do
        sign_out admin
        visit admin_users_path
      end

      it "redirects to sign in page" do
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  describe "Turbo Frame navigation" do
    it "navigates without full page reload", :uses_javascript do
      visit admin_metrics_path

      # Click users link in sidebar
      click_link "Users"

      # Should update content without full reload
      expect(page).to have_current_path(admin_users_path)
      expect(page).to have_text("Users")

      # Sidebar should still be visible
      expect(page).to have_css("aside")
    end
  end
end
