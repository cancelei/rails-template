require "rails_helper"

RSpec.describe "Admin Tours Management" do
  let(:admin) { FactoryBot.create(:user, :admin) }
  let(:guide) { FactoryBot.create(:user, :guide) }
  let!(:tours) { FactoryBot.create_list(:tour, 3, guide:) }

  before do
    sign_in admin
    visit admin_tours_path
  end

  describe "Tours index page" do
    it "displays all tours" do
      expect(page).to have_text("Tours")
      tours.each do |tour|
        expect(page).to have_text(tour.title)
      end
    end

    it "allows filtering by status" do
      select "Scheduled", from: "status"

      tours.each do |tour|
        expect(page).to have_text(tour.title)
      end
    end

    it "allows searching tours" do
      tour = tours.first
      fill_in "q", with: tour.title
      sleep 0.4

      expect(page).to have_text(tour.title)
    end

    it "displays tour details" do
      tour = tours.first
      within "##{dom_id(tour)}" do
        expect(page).to have_text(tour.title)
        expect(page).to have_text(tour.location_name)
        expect(page).to have_text(tour.guide.name)
      end
    end
  end

  describe "Tour actions" do
    it "allows editing tours", :uses_javascript do
      click_link "Edit", match: :first

      within "#modal" do
        expect(page).to have_field("Title")
      end
    end

    it "allows deleting tours" do
      tour = tours.first

      accept_confirm do
        within "##{dom_id(tour)}" do
          click_button "Delete"
        end
      end

      expect(page).to have_no_text(tour.title)
    end
  end

  describe "Status badges" do
    it "displays correct status badge colors" do
      tour = tours.first
      within "##{dom_id(tour)}" do
        expect(page).to have_css(".bg-blue-100")
      end
    end
  end
end
