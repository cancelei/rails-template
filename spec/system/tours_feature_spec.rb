require "rails_helper"

RSpec.describe "Tours" do
  let(:guide) { FactoryBot.create(:user, :guide) }
  let(:tourist) { FactoryBot.create(:user, :tourist) }
  let(:tour) { FactoryBot.create(:tour, guide:) }

  describe "Tours index page" do
    before do
      Tour.destroy_all
      FactoryBot.create_list(:tour, 3, guide:)
      visit tours_path
    end

    it "displays all available tours" do
      expect(page).to have_text("Tours")
      expect(page).to have_css(".card", minimum: 3)
    end

    it_behaves_like "an accessible page"

    context "when no tours are available" do
      before do
        Tour.destroy_all
        visit tours_path
      end

      it "shows a message about no tours" do
        expect(page).to have_text("No tours available at the moment")
      end
    end

    context "when user is a guide" do
      before do
        sign_in guide
        visit tours_path
      end

      it "shows a create tour button" do
        expect(page).to have_link("Create New Tour")
      end
    end
  end

  describe "Tour show page" do
    before do
      tour
      visit tour_path(tour)
    end

    it "displays tour details" do
      expect(page).to have_text(tour.title)
      expect(page).to have_text(tour.description)
      expect(page).to have_text(tour.location_name)
    end

    it_behaves_like "an accessible page"

    context "when user is signed in as a tourist" do
      before do
        sign_in tourist
        visit tour_path(tour)
      end

      it "allows booking the tour" do
        expect(page).to have_button("Book Tour")
      end
    end
  end

  describe "Tour creation" do
    before do
      sign_in guide
      visit new_tour_path
    end

    it_behaves_like "an accessible page"

    it "allows a guide to create a tour" do
      fill_in "Title", with: "Amazing Mountain Hike"
      fill_in "Description", with: "A beautiful hike through the mountains"
      fill_in "Location name", with: "Rocky Mountains"
      fill_in "Capacity", with: "10"
      fill_in "Price cents", with: "5000"
      fill_in "Currency", with: "USD"
      fill_in "Latitude", with: "40.7128"
      fill_in "Longitude", with: "-74.0060"
      fill_in "Starts at", with: 1.week.from_now.to_s
      fill_in "Ends at", with: 2.weeks.from_now.to_s

      click_on "Create Tour"

      expect(page).to have_text("Tour was successfully created")
      expect(page).to have_text("Amazing Mountain Hike")
    end

    context "when required fields are missing" do
      it "shows validation errors" do
        click_on "Create Tour"

        expect(page).to have_text("can't be blank")
      end
    end
  end

  describe "Tour editing" do
    before do
      sign_in guide
      visit edit_tour_path(tour)
    end

    it_behaves_like "an accessible page"

    it "allows a guide to edit their tour" do
      fill_in "Title", with: "Updated Tour Title"
      click_on "Update Tour"

      expect(page).to have_text("Tour was successfully updated")
      expect(page).to have_text("Updated Tour Title")
    end

    context "when user is not the tour owner" do
      before do
        sign_in tourist
        visit edit_tour_path(tour)
      end

      it "redirects unauthorized users" do
        expect(page).to have_current_path(root_path, ignore_query: true)
      end
    end
  end
end
