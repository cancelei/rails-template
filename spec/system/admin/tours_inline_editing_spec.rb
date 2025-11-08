# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Tours Inline Editing" do
  let(:admin) { create(:user, role: :admin) }
  let(:guide) { create(:user, role: :guide) }
  let!(:tour) { create(:tour, guide:, title: "Original Tour Title", capacity: 10, status: "scheduled") }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in admin
  end

  describe "inline editing from tours index page" do
    before do
      visit admin_tours_path
    end

    it "displays tour in table" do
      expect(page).to have_content(tour.title)
      expect(page).to have_content(guide.name)
      expect(page).to have_content("Scheduled")
    end

    it "allows editing a tour inline", :js do
      # Find the tour row and click edit
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      # Form should appear in place
      expect(page).to have_content("Edit Tour")
      expect(page).to have_field("Title", with: tour.title)
      expect(page).to have_field("Capacity", with: "10")

      # Update the tour
      fill_in "Title", with: "Updated Inline Tour Title"
      fill_in "Capacity", with: "20"
      select "Done", from: "Status"

      click_button "Save Changes"

      # Should see success notification
      expect(page).to have_content("Tour updated successfully")

      # Row should update with new values
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        expect(page).to have_content("Updated Inline Tour Title")
        expect(page).to have_no_field("Title") # Form should be gone
      end

      # Verify database was updated
      tour.reload
      expect(tour.title).to eq("Updated Inline Tour Title")
      expect(tour.capacity).to eq(20)
      expect(tour.status).to eq("done")
    end

    it "allows canceling inline edit", :js do
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      expect(page).to have_content("Edit Tour")

      # Click cancel
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Cancel"
      end

      # Should return to display mode
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        expect(page).to have_content(tour.title)
        expect(page).to have_no_field("Title")
      end
    end

    it "shows validation errors inline", :js do
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      # Clear required field
      fill_in "Title", with: ""

      click_button "Save Changes"

      # Should show error message
      expect(page).to have_content("error")
      expect(page).to have_field("Title") # Form should still be visible

      # Database should not be updated
      tour.reload
      expect(tour.title).not_to be_blank
    end

    it "shows admin-specific fields", :js do
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      # Admin should see additional fields
      expect(page).to have_field("Currency")
      expect(page).to have_field("Latitude")
      expect(page).to have_field("Longitude")
    end

    it "updates tour type and booking deadline", :js do
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      select "Private Tour", from: "Tour type"

      # Wait for conditional field to appear
      expect(page).to have_field("Booking deadline")

      select "24 hours before start", from: "Booking deadline"

      click_button "Save Changes"

      expect(page).to have_content("Tour updated successfully")

      tour.reload
      expect(tour.tour_type).to eq("private_tour")
      expect(tour.booking_deadline_hours).to eq(24)
    end
  end

  describe "inline editing from guide profile page" do
    before do
      visit admin_guide_profile_path(guide.guide_profile)
    end

    it "displays tours in guide profile" do
      expect(page).to have_content(guide.name)
      expect(page).to have_content(tour.title)
    end

    it "allows editing tour from guide profile", :js do
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      expect(page).to have_content("Edit Tour")

      fill_in "Title", with: "Updated from Profile"

      click_button "Save Changes"

      expect(page).to have_content("Tour updated successfully")
      expect(page).to have_content("Updated from Profile")

      tour.reload
      expect(tour.title).to eq("Updated from Profile")
    end
  end

  describe "multiple tours editing" do
    let!(:tour2) { create(:tour, guide:, title: "Second Tour") }
    let!(:tour3) { create(:tour, guide:, title: "Third Tour") }

    before do
      visit admin_tours_path
    end

    it "can edit different tours sequentially", :js do
      # Edit first tour
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
        fill_in "Title", with: "First Updated"
        click_button "Save Changes"
      end

      expect(page).to have_content("First Updated")

      # Edit second tour
      within("##{ActionView::RecordIdentifier.dom_id(tour2)}") do
        click_link "Edit"
        fill_in "Title", with: "Second Updated"
        click_button "Save Changes"
      end

      expect(page).to have_content("Second Updated")

      # Both should be updated
      tour.reload
      tour2.reload
      expect(tour.title).to eq("First Updated")
      expect(tour2.title).to eq("Second Updated")
    end
  end

  describe "accessibility" do
    before do
      visit admin_tours_path
    end

    it "has accessible form labels", :js do
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      expect(page).to have_css("label[for*='title']", text: "Title")
      expect(page).to have_css("label[for*='capacity']", text: "Max Capacity")
      expect(page).to have_css("label[for*='description']", text: "Description")
    end

    it "has keyboard accessible controls", :js do
      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      # Tab through form fields
      find_field("Title").send_keys(:tab)
      expect(page).to have_css(":focus", text: "", visible: :all)

      # Should be able to submit with Enter key
      fill_in "Title", with: "Keyboard Test"
      find_button("Save Changes").send_keys(:return)

      expect(page).to have_content("Tour updated successfully")
    end
  end

  describe "real-time updates", :js do
    it "shows loading state during save" do
      visit admin_tours_path

      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      fill_in "Title", with: "Loading Test"

      # Save button should have loading state functionality
      save_button = find_button("Save Changes")
      expect(save_button[:class]).to include("btn")
    end

    it "updates immediately without page reload" do
      visit admin_tours_path

      # Store current URL
      original_url = current_url

      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
        fill_in "Title", with: "No Reload Test"
        click_button "Save Changes"
      end

      # Wait for update
      expect(page).to have_content("No Reload Test")

      # URL should not change (no page reload)
      expect(current_url).to eq(original_url)
    end
  end

  describe "responsive behavior" do
    it "renders form on mobile viewport", driver: :selenium_chrome_headless do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size

      visit admin_tours_path

      within("##{ActionView::RecordIdentifier.dom_id(tour)}") do
        click_link "Edit"
      end

      expect(page).to have_content("Edit Tour")
      expect(page).to have_field("Title")
      expect(page).to have_button("Save Changes")
    end
  end
end
