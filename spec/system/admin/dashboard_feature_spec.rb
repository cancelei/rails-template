require "rails_helper"

RSpec.describe "Admin Dashboard" do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let!(:guides) { FactoryBot.create_list(:user, 5, :guide) }
  let!(:tourists) { FactoryBot.create_list(:user, 10, :tourist) }
  let!(:tours) { FactoryBot.create_list(:tour, 7) }
  let!(:bookings) { FactoryBot.create_list(:booking, 3) }

  before do
    sign_in admin
    visit admin_metrics_path
  end

  describe "Metrics display" do
    it "displays guide count" do
      expect(page).to have_text("Guides")
      expect(page).to have_text("5")
    end

    it "displays tourist count" do
      expect(page).to have_text("Tourists")
      expect(page).to have_text("10")
    end

    it "displays total tours count" do
      expect(page).to have_text("Total Tours")
      expect(page).to have_text("7")
    end

    it "displays booking counts" do
      expect(page).to have_text("Bookings (Last 7 Days)")
      expect(page).to have_text("Bookings (Last 30 Days)")
    end
  end

  describe "Recent bookings" do
    it "displays recent booking activity" do
      expect(page).to have_text("Recent Bookings")
      bookings.take(3).each do |booking|
        expect(page).to have_text(booking.tour.title)
        expect(page).to have_text(booking.user.name)
      end
    end
  end

  describe "Navigation" do
    it "provides links to all admin sections" do
      expect(page).to have_link("Users")
      expect(page).to have_link("Tours")
      expect(page).to have_link("Bookings")
      expect(page).to have_link("Reviews")
      expect(page).to have_link("Guide Profiles")
      expect(page).to have_link("Weather")
      expect(page).to have_link("Email Logs")
    end
  end

  describe "Admin layout" do
    it "displays admin header" do
      expect(page).to have_css("header")
      expect(page).to have_text(admin.name)
    end

    it "displays sidebar navigation" do
      expect(page).to have_css("aside")
      expect(page).to have_text("Guide Admin")
    end

    it "has sign out functionality" do
      click_button "Sign Out"

      expect(page).to have_current_path(root_path)
    end
  end
end
