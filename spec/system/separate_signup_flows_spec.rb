require "rails_helper"

RSpec.describe "Separate Signup Flows" do
  before do
    driven_by(:rack_test)
  end

  describe "Homepage" do
    context "when user is not signed in" do
      it "displays both signup options" do
        visit root_path

        expect(page).to have_content("I'm a Tourist")
        expect(page).to have_content("I'm a Tour Guide")
        expect(page).to have_link("Sign up as Tourist", href: new_tourist_registration_path)
        expect(page).to have_link("Sign up as Guide", href: new_guide_registration_path)
      end
    end

    context "when user is signed in as tourist" do
      it "shows browse tours button" do
        tourist = create(:user, role: :tourist)
        sign_in tourist

        visit root_path

        expect(page).to have_link("Browse Tours")
        expect(page).to have_no_content("I'm a Tourist")
        expect(page).to have_no_content("I'm a Tour Guide")
      end
    end

    context "when user is signed in as guide" do
      it "shows guide dashboard and create tour buttons" do
        guide = create(:user, role: :guide)
        sign_in guide

        visit root_path

        expect(page).to have_link("My Dashboard")
        expect(page).to have_link("Create Tour")
        expect(page).to have_no_content("I'm a Tourist")
      end
    end
  end

  describe "Tourist Signup Flow" do
    it "allows tourist to sign up" do
      visit new_tourist_registration_path

      expect(page).to have_content("Join as a Tourist")
      expect(page).to have_content("Discover and book amazing tours")

      fill_in "Name", with: "John Tourist"
      fill_in "Email", with: "john@example.com"
      fill_in "Password", with: "password1234567890"
      fill_in "Confirm Password", with: "password1234567890"

      click_button "Create Tourist Account"

      # Debug output
      # puts page.html if User.find_by(email: "john@example.com").nil?

      user = User.find_by(email: "john@example.com")
      expect(user).to be_present, "User was not created. Page content: #{page.body[0..500]}"
      expect(user.role).to eq("tourist")
      expect(user.name).to eq("John Tourist")
      expect(page).to have_current_path(root_path)
    end

    it "shows link to guide signup" do
      visit new_tourist_registration_path

      expect(page).to have_content("Are you a tour guide?")
      expect(page).to have_link("Sign up as a guide", href: new_guide_registration_path)
    end

    it "shows validation errors" do
      visit new_tourist_registration_path

      fill_in "Name", with: ""
      fill_in "Email", with: "invalid"
      fill_in "Password", with: "short"
      fill_in "Confirm Password", with: "different"

      click_button "Create Tourist Account"

      expect(page).to have_content("error")
    end
  end

  describe "Guide Signup Flow" do
    it "allows guide to sign up and redirects to profile setup" do
      visit new_guide_registration_path

      expect(page).to have_content("Become a Tour Guide")
      expect(page).to have_content("Share your passion and create unforgettable experiences")
      expect(page).to have_content("After creating your account, you'll set up your profile")

      fill_in "Name", with: "Jane Guide"
      fill_in "Email", with: "jane@example.com"
      fill_in "Password", with: "password1234567890"
      fill_in "Confirm Password", with: "password1234567890"

      click_button "Create Guide Account"

      user = User.find_by(email: "jane@example.com")
      expect(user).to be_present
      expect(user.role).to eq("guide")
      expect(user.name).to eq("Jane Guide")
      expect(user.guide_profile).to be_present
      expect(page).to have_current_path(edit_guide_dashboard_path)
    end

    it "shows link to tourist signup" do
      visit new_guide_registration_path

      expect(page).to have_content("Just looking to book tours?")
      expect(page).to have_link("Sign up as a tourist", href: new_tourist_registration_path)
    end

    it "shows validation errors" do
      visit new_guide_registration_path

      fill_in "Name", with: ""
      fill_in "Email", with: "invalid"
      fill_in "Password", with: "short"
      fill_in "Confirm Password", with: "different"

      click_button "Create Guide Account"

      expect(page).to have_content("error")
    end
  end

  describe "Cross-links between signup pages" do
    it "allows navigation from tourist to guide signup" do
      visit new_tourist_registration_path
      click_link "Sign up as a guide"

      expect(page).to have_current_path(new_guide_registration_path)
      expect(page).to have_content("Become a Tour Guide")
    end

    it "allows navigation from guide to tourist signup" do
      visit new_guide_registration_path
      click_link "Sign up as a tourist"

      expect(page).to have_current_path(new_tourist_registration_path)
      expect(page).to have_content("Join as a Tourist")
    end
  end
end
