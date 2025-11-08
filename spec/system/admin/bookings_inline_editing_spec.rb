# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Bookings Inline Editing" do
  let(:admin) { create(:user, role: :admin) }
  let(:guide) { create(:user, role: :guide) }
  let(:tourist) { create(:user, role: :tourist) }
  let(:tour) { create(:tour, guide:) }
  let!(:booking) { create(:booking, tour:, user: tourist, status: "pending") }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in admin
  end

  describe "inline editing from bookings index page" do
    before do
      visit admin_bookings_path
    end

    it "displays booking in table" do
      expect(page).to have_content(booking.tour.title)
      expect(page).to have_content(booking.user.name)
      expect(page).to have_content(booking.user.email)
      expect(page).to have_content("Pending")
    end

    it "allows editing a booking inline", :js do
      # Find the booking row and click edit
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      # Form should appear in place
      expect(page).to have_content("Edit Booking")
      expect(page).to have_content(booking.tour.title)
      expect(page).to have_content(booking.user.name)

      # Update the booking
      select "Confirmed", from: "Booking Status"
      fill_in "Notes", with: "Customer confirmed via phone. Vegetarian meal requested."

      click_button "Save Changes"

      # Should see success notification
      expect(page).to have_content("Booking updated successfully")

      # Row should update with new status
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        expect(page).to have_content("Confirmed")
        expect(page).to have_no_field("Booking Status") # Form should be gone
      end

      # Verify database was updated
      booking.reload
      expect(booking.status).to eq("confirmed")
      expect(booking.notes).to eq("Customer confirmed via phone. Vegetarian meal requested.")
    end

    it "allows canceling inline edit", :js do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      expect(page).to have_content("Edit Booking")

      # Click cancel
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Cancel"
      end

      # Should return to display mode
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        expect(page).to have_content(booking.tour.title)
        expect(page).to have_no_field("Booking Status")
      end

      # Database should not have changed
      booking.reload
      expect(booking.status).to eq("pending")
    end

    it "updates booking status from pending to confirmed", :js do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      select "Confirmed", from: "Booking Status"
      click_button "Save Changes"

      expect(page).to have_content("Booking updated successfully")

      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        expect(page).to have_content("Confirmed")
      end

      booking.reload
      expect(booking.status).to eq("confirmed")
    end

    it "updates booking status to cancelled", :js do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      select "Cancelled", from: "Booking Status"
      fill_in "Notes", with: "Customer requested cancellation due to travel restrictions"
      click_button "Save Changes"

      expect(page).to have_content("Booking updated successfully")

      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        expect(page).to have_content("Cancelled")
      end

      booking.reload
      expect(booking.status).to eq("cancelled")
      expect(booking.notes).to include("travel restrictions")
    end

    it "allows updating notes without changing status", :js do
      confirmed_booking = create(:booking, tour:, user: tourist, status: "confirmed")

      visit admin_bookings_path

      within("##{ActionView::RecordIdentifier.dom_id(confirmed_booking)}") do
        click_link "Edit"
      end

      fill_in "Notes", with: "Additional requirements: wheelchair accessible transportation"

      # Keep status the same
      expect(page).to have_select("Booking Status", selected: "Confirmed")

      click_button "Save Changes"

      expect(page).to have_content("Booking updated successfully")

      confirmed_booking.reload
      expect(confirmed_booking.status).to eq("confirmed")
      expect(confirmed_booking.notes).to include("wheelchair accessible")
    end
  end

  describe "multiple bookings editing" do
    let!(:booking2) { create(:booking, tour:, user: tourist, status: "pending") }
    let!(:booking3) { create(:booking, tour:, user: tourist, status: "confirmed") }

    before do
      visit admin_bookings_path
    end

    it "can edit different bookings sequentially", :js do
      # Edit first booking
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
        select "Confirmed", from: "Booking Status"
        click_button "Save Changes"
      end

      expect(page).to have_content("Booking updated successfully")

      # Edit second booking
      within("##{ActionView::RecordIdentifier.dom_id(booking2)}") do
        click_link "Edit"
        select "Cancelled", from: "Booking Status"
        fill_in "Notes", with: "Duplicate booking"
        click_button "Save Changes"
      end

      expect(page).to have_content("Booking updated successfully")

      # Both should be updated
      booking.reload
      booking2.reload
      expect(booking.status).to eq("confirmed")
      expect(booking2.status).to eq("cancelled")
      expect(booking2.notes).to eq("Duplicate booking")
    end
  end

  describe "status filtering" do
    let!(:confirmed_booking) { create(:booking, tour:, user: tourist, status: "confirmed") }
    let!(:cancelled_booking) { create(:booking, tour:, user: tourist, status: "cancelled") }

    before do
      visit admin_bookings_path
    end

    it "filters bookings by status", :js do
      # Initially shows all bookings
      expect(page).to have_content(booking.tour.title)
      expect(page).to have_content(confirmed_booking.tour.title)

      # Filter for confirmed only
      select "Confirmed", from: "status"

      # Should only show confirmed booking
      expect(page).to have_content(confirmed_booking.tour.title)
      expect(page).to have_no_content("Pending") # booking is pending
    end

    it "can edit filtered bookings inline", :js do
      select "Pending", from: "status"

      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
        select "Confirmed", from: "Booking Status"
        click_button "Save Changes"
      end

      expect(page).to have_content("Booking updated successfully")

      booking.reload
      expect(booking.status).to eq("confirmed")
    end
  end

  describe "accessibility" do
    before do
      visit admin_bookings_path
    end

    it "has accessible form labels", :js do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      expect(page).to have_css("label[for*='status']", text: "Booking Status")
      expect(page).to have_css("label[for*='notes']", text: "Notes")
    end

    it "has keyboard accessible controls", :js do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      # Tab through form fields
      find_select("Booking Status").send_keys(:tab)
      expect(find_field("Notes")).to be_focused
    end
  end

  describe "real-time updates", :js do
    it "updates immediately without page reload" do
      visit admin_bookings_path

      # Store current URL
      original_url = current_url

      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
        select "Confirmed", from: "Booking Status"
        click_button "Save Changes"
      end

      # Wait for update
      expect(page).to have_content("Confirmed")

      # URL should not change (no page reload)
      expect(current_url).to eq(original_url)
    end

    it "shows notification that auto-dismisses" do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
        select "Confirmed", from: "Booking Status"
        click_button "Save Changes"
      end

      # Notification should appear
      notification_area = find_by_id("notifications")
      within(notification_area) do
        expect(page).to have_content("Booking updated successfully")
      end
    end
  end

  describe "displaying booking context" do
    before do
      visit admin_bookings_path
    end

    it "shows tour and user information in edit form", :js do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      # Should show context about what's being edited
      expect(page).to have_content(booking.tour.title)
      expect(page).to have_content(booking.user.name)
    end

    it "maintains booking relationships after edit", :js do
      original_tour_id = booking.tour_id
      original_user_id = booking.user_id

      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
        select "Confirmed", from: "Booking Status"
        click_button "Save Changes"
      end

      booking.reload
      expect(booking.tour_id).to eq(original_tour_id)
      expect(booking.user_id).to eq(original_user_id)
    end
  end

  describe "responsive behavior" do
    it "renders form on mobile viewport", driver: :selenium_chrome_headless do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone size

      visit admin_bookings_path

      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      expect(page).to have_content("Edit Booking")
      expect(page).to have_select("Booking Status")
      expect(page).to have_button("Save Changes")
    end
  end

  describe "notes management" do
    before do
      visit admin_bookings_path
    end

    it "allows adding long notes", :js do
      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
      end

      long_note = "Customer has special dietary requirements. " * 10
      fill_in "Notes", with: long_note

      click_button "Save Changes"

      expect(page).to have_content("Booking updated successfully")

      booking.reload
      expect(booking.notes).to eq(long_note)
    end

    it "allows clearing existing notes", :js do
      booking.update(notes: "Some existing notes")
      visit admin_bookings_path

      within("##{ActionView::RecordIdentifier.dom_id(booking)}") do
        click_link "Edit"
        fill_in "Notes", with: ""
        click_button "Save Changes"
      end

      expect(page).to have_content("Booking updated successfully")

      booking.reload
      expect(booking.notes).to be_blank
    end
  end
end
