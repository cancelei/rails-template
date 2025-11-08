require "rails_helper"

RSpec.describe "Tour Add-ons Feature" do
  let(:guide) { create(:user, role: :guide) }
  let(:tourist) { create(:user, role: :tourist) }
  let!(:guide_profile) { create(:guide_profile, user: guide) }
  let!(:tour) do
    create(:tour, guide:, price_cents: 10_000, capacity: 10, currency: "BRL", tour_type: :public_tour)
  end

  describe "Tourist viewing and booking with add-ons" do
    let!(:add_on_1) do
      create(:tour_add_on,
             tour:,
             name: "Hotel Pickup",
             price_cents: 2000,
             pricing_type: :per_person,
             active: true)
    end
    let!(:add_on_2) do
      create(:tour_add_on,
             tour:,
             name: "Professional Photos",
             price_cents: 5000,
             pricing_type: :flat_fee,
             active: true)
    end
    let!(:inactive_add_on) do
      create(:tour_add_on,
             tour:,
             name: "Inactive Add-on",
             active: false)
    end

    before do
      sign_in tourist
      visit tour_path(tour)
    end

    it "displays active add-ons on tour detail page" do
      expect(page).to have_content("Enhance Your Experience")
      expect(page).to have_content("Hotel Pickup")
      expect(page).to have_content("Professional Photos")
      expect(page).to have_no_content("Inactive Add-on")
    end

    it "shows add-on pricing information" do
      expect(page).to have_content("R$20.00 per person")
      expect(page).to have_content("R$50.00")
    end

    it "displays add-on checkboxes in booking form" do
      expect(page).to have_css("input[name='add_on_ids[]'][value='#{add_on_1.id}']")
      expect(page).to have_css("input[name='add_on_ids[]'][value='#{add_on_2.id}']")
    end

    it "creates booking with selected add-ons" do
      fill_in "Number of spots", with: "2"
      check "add_on_ids[]", match: :first # Select Hotel Pickup

      click_button "Book Now"

      expect(page).to have_content("Booking was successful")

      booking = Booking.last
      expect(booking.booking_add_ons.count).to eq(1)
      expect(booking.booking_add_ons.first.tour_add_on).to eq(add_on_1)
      expect(booking.booking_add_ons.first.price_cents_at_booking).to eq(2000)
    end

    it "creates booking with multiple add-ons" do
      fill_in "Number of spots", with: "1"
      all(:css, "input[name='add_on_ids[]']").each(&:check)

      click_button "Book Now"

      expect(page).to have_content("Booking was successful")

      booking = Booking.last
      expect(booking.booking_add_ons.count).to eq(2)
    end

    it "creates booking without add-ons when none selected" do
      fill_in "Number of spots", with: "1"

      click_button "Book Now"

      expect(page).to have_content("Booking was successful")

      booking = Booking.last
      expect(booking.booking_add_ons.count).to eq(0)
    end
  end

  describe "Admin managing tour add-ons" do
    let(:admin) { create(:user, role: :admin) }

    before do
      sign_in admin
    end

    it "allows admin to view add-ons management page" do
      visit admin_tour_tour_add_ons_path(tour)

      expect(page).to have_content("Manage Add-ons")
      expect(page).to have_content(tour.title)
    end

    it "displays add-on form fields" do
      visit admin_tour_tour_add_ons_path(tour)

      expect(page).to have_field("Name")
      expect(page).to have_field("Description")
      expect(page).to have_select("Type")
      expect(page).to have_field("Price (cents)")
    end

    it "shows existing add-ons" do
      create(:tour_add_on, tour:, name: "Test Add-on", price_cents: 1000)

      visit admin_tour_tour_add_ons_path(tour)

      expect(page).to have_content("Test Add-on")
      expect(page).to have_content("R$10.00")
    end
  end

  describe "Add-on model behavior" do
    it "displays correct currency symbols for different currencies" do
      usd_add_on = create(:tour_add_on, tour:, currency: "USD", price_cents: 2500)
      eur_add_on = create(:tour_add_on, tour:, currency: "EUR", price_cents: 3000)

      expect(usd_add_on.formatted_price).to include("$25.00")
      expect(eur_add_on.formatted_price).to include("€30.00")
    end

    it "displays correct icons for different add-on types" do
      transportation = create(:tour_add_on, tour:, addon_type: :transportation)
      food = create(:tour_add_on, tour:, addon_type: :food_beverage)
      photography = create(:tour_add_on, tour:, addon_type: :photography)
      equipment = create(:tour_add_on, tour:, addon_type: :equipment)

      expect(transportation.addon_type_icon).to eq("🚗")
      expect(food.addon_type_icon).to eq("🍽️")
      expect(photography.addon_type_icon).to eq("📸")
      expect(equipment.addon_type_icon).to eq("🎒")
    end

    it "calculates per-person pricing correctly" do
      add_on = create(:tour_add_on, tour:, price_cents: 1000, pricing_type: :per_person)

      expect(add_on.total_price(1)).to eq(1000)
      expect(add_on.total_price(3)).to eq(3000)
    end

    it "calculates flat-fee pricing correctly" do
      add_on = create(:tour_add_on, tour:, price_cents: 5000, pricing_type: :flat_fee)

      expect(add_on.total_price(1)).to eq(5000)
      expect(add_on.total_price(10)).to eq(5000)
    end
  end

  describe "Historical pricing preservation" do
    let!(:add_on) do
      create(:tour_add_on,
             tour:,
             price_cents: 1000,
             pricing_type: :per_person)
    end

    before do
      sign_in tourist
    end

    it "preserves add-on price at time of booking" do
      visit tour_path(tour)

      fill_in "Number of spots", with: "2"
      check "add_on_ids[]", match: :first
      click_button "Book Now"

      booking = Booking.last
      booking_add_on = booking.booking_add_ons.first

      # Verify price was captured at booking time
      expect(booking_add_on.price_cents_at_booking).to eq(1000)
      original_total = booking_add_on.total_price

      # Change the add-on price
      add_on.update!(price_cents: 5000)

      # Booking should still use original price
      booking_add_on.reload
      expect(booking_add_on.total_price).to eq(original_total)
      expect(booking_add_on.total_price).to eq(2000) # 1000 * 2 spots
    end
  end

  describe "Add-ons display and integration" do
    it "only shows active add-ons to tourists" do
      create(:tour_add_on, tour:, name: "Active", active: true)
      create(:tour_add_on, tour:, name: "Inactive", active: false)

      sign_in tourist
      visit tour_path(tour)

      expect(page).to have_content("Active")
      expect(page).to have_no_content("Inactive")
    end
  end
end
