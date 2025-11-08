# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Automated Accessibility Tests" do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "Home page accessibility" do
    let(:guide) { create(:user, :guide) }
    let!(:tour) { create(:tour, guide:) }

    it "has no accessibility violations on home page" do
      visit root_path
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
    end

    context "when user is signed in" do
      let(:user) { create(:user) }
      let!(:booking) { create(:booking, user:, tour:) }

      it "has no accessibility violations for authenticated user" do
        sign_in user
        visit root_path
        expect(page).to be_axe_clean
          .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
      end
    end
  end

  describe "Tours page accessibility" do
    let(:guide) { create(:user, :guide) }
    let!(:tours) { create_list(:tour, 3, guide:) }

    it "has no accessibility violations on tours index" do
      visit tours_path
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
    end

    it "has no accessibility violations on tour show page" do
      visit tour_path(tours.first)
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
    end
  end

  describe "Authentication pages accessibility" do
    it "has no accessibility violations on sign in page" do
      visit new_user_session_path
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
    end

    it "has no accessibility violations on sign up page" do
      visit new_user_registration_path
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
    end
  end

  describe "Admin pages accessibility" do
    let(:admin) { create(:user, :admin) }

    before do
      sign_in admin
    end

    it "has no accessibility violations on admin dashboard" do
      visit admin_path
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
    end
  end

  describe "Color contrast checks" do
    let(:guide) { create(:user, :guide) }
    let!(:tour) { create(:tour, guide:) }

    it "passes color contrast requirements" do
      visit tours_path

      # This specifically checks for color contrast issues
      expect(page).to be_axe_clean.checking_only(:color_contrast)
    end

    it "has sufficient contrast on gradient backgrounds" do
      user = create(:user)
      create(:booking, user:, tour:)
      sign_in user
      visit root_path

      # Check that gradient backgrounds maintain contrast
      expect(page).to be_axe_clean.checking_only(:color_contrast)
    end
  end
end
