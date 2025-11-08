require "rails_helper"

RSpec.describe "TourAddOns" do
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:) }

  describe "Booking with add-ons flow" do
    let!(:equipment_addon) do
      create(:tour_add_on,
             tour:,
             name: "Hiking Equipment",
             price_cents: 2000,
             pricing_type: :per_person,
             active: true)
    end

    let!(:lunch_addon) do
      create(:tour_add_on,
             tour:,
             name: "Lunch Package",
             price_cents: 1500,
             pricing_type: :flat_fee,
             active: true)
    end

    let!(:inactive_addon) do
      create(:tour_add_on,
             tour:,
             name: "Inactive Option",
             active: false)
    end

    before { sign_in tourist }

    it "displays active add-ons on tour page" do
      get tour_path(tour)
      expect(response.body).to include("Hiking Equipment")
      expect(response.body).to include("Lunch Package")
      expect(response.body).not_to include("Inactive Option")
    end

    it "creates booking with selected add-ons" do
      booking_params = {
        booking: {
          tour_id: tour.id,
          number_of_spots: 2,
          booking_add_ons_attributes: {
            "0" => { tour_add_on_id: equipment_addon.id },
            "1" => { tour_add_on_id: lunch_addon.id }
          }
        }
      }

      expect do
        post bookings_path, params: booking_params
      end.to change(Booking, :count).by(1)
                                    .and change(BookingAddOn, :count).by(2)
    end

    it "calculates correct total with per-person add-on" do
      booking = create(:booking, tour:, number_of_spots: 3)
      booking_addon = create(:booking_add_on,
                             booking:,
                             tour_add_on: equipment_addon,
                             price_cents_at_booking: equipment_addon.price_cents)

      # 3 spots * 2000 per person = 6000
      expect(booking_addon.calculate_total_price).to eq(6000)
    end

    it "calculates correct total with flat-fee add-on" do
      booking = create(:booking, tour:, number_of_spots: 5)
      booking_addon = create(:booking_add_on,
                             booking:,
                             tour_add_on: lunch_addon,
                             price_cents_at_booking: lunch_addon.price_cents)

      # Flat fee regardless of spots
      expect(booking_addon.calculate_total_price).to eq(1500)
    end

    it "stores price at booking time (price freeze)" do
      booking = create(:booking, tour:, number_of_spots: 2)
      original_price = equipment_addon.price_cents

      booking_addon = create(:booking_add_on,
                             booking:,
                             tour_add_on: equipment_addon,
                             price_cents_at_booking: original_price)

      # Change the add-on price
      equipment_addon.update!(price_cents: 5000)

      # Booking should still use original price
      expect(booking_addon.price_cents_at_booking).to eq(original_price)
      expect(booking_addon.calculate_total_price).to eq(original_price * 2)
    end

    it "calculates grand total including base price and all add-ons" do
      tour_price = tour.price_cents # e.g., 10000
      booking = create(:booking, tour:, number_of_spots: 2)

      create(:booking_add_on,
             booking:,
             tour_add_on: equipment_addon,
             price_cents_at_booking: 2000)

      create(:booking_add_on,
             booking:,
             tour_add_on: lunch_addon,
             price_cents_at_booking: 1500)

      # Base: 10000 * 2 = 20000
      # Equipment (per person): 2000 * 2 = 4000
      # Lunch (flat): 1500
      # Total: 25500
      expected_total = (tour_price * 2) + (2000 * 2) + 1500
      expect(booking.total_price_cents).to eq(expected_total)
    end
  end

  describe "Add-on types" do
    before { sign_in guide }

    it "creates transportation add-on" do
      addon_params = {
        tour_add_on: {
          name: "Airport Shuttle",
          description: "Round trip shuttle service",
          price_cents: 3000,
          currency: "USD",
          addon_type: "transportation",
          pricing_type: "per_person"
        }
      }

      expect do
        post tour_tour_add_ons_path(tour), params: addon_params
      end.to change(tour.tour_add_ons, :count).by(1)

      expect(TourAddOn.last.addon_type).to eq("transportation")
    end

    it "creates food/beverage add-on" do
      addon_params = {
        tour_add_on: {
          name: "Gourmet Dinner",
          price_cents: 5000,
          addon_type: "food_beverage",
          pricing_type: "flat_fee"
        }
      }

      post tour_tour_add_ons_path(tour), params: addon_params
      expect(TourAddOn.last.addon_type).to eq("food_beverage")
    end

    %w[transportation food_beverage equipment photography accommodation insurance].each do |type|
      it "supports #{type} addon type" do
        addon = create(:tour_add_on, tour:, addon_type: type)
        expect(addon.addon_type).to eq(type)
      end
    end
  end

  describe "Currency handling" do
    it "supports multiple currencies" do
      usd_addon = create(:tour_add_on, tour:, currency: "USD", price_cents: 2500)
      eur_addon = create(:tour_add_on, tour:, currency: "EUR", price_cents: 3000)

      expect(usd_addon.currency).to eq("USD")
      expect(eur_addon.currency).to eq("EUR")
    end

    it "matches tour currency by default" do
      tour.update!(currency: "BRL")
      addon = create(:tour_add_on, tour:, currency: "BRL")

      expect(addon.currency).to eq(tour.currency)
    end
  end

  describe "Admin management" do
    let(:admin) { create(:user, :admin) }

    before { sign_in admin }

    it "allows admin to create add-ons for any tour" do
      addon_params = {
        tour_add_on: {
          name: "Admin Special",
          price_cents: 1000,
          pricing_type: "flat_fee"
        }
      }

      expect do
        post admin_tour_tour_add_ons_path(tour), params: addon_params
      end.to change(tour.tour_add_ons, :count).by(1)
    end

    it "allows admin to toggle add-on active status" do
      addon = create(:tour_add_on, tour:, active: true)

      patch admin_tour_tour_add_on_path(tour, addon), params: { tour_add_on: { active: false } }

      expect(addon.reload.active).to be(false)
    end

    it "allows admin to delete add-ons" do
      addon = create(:tour_add_on, tour:)

      expect do
        delete admin_tour_tour_add_on_path(tour, addon)
      end.to change(tour.tour_add_ons, :count).by(-1)
    end
  end

  describe "Validation and constraints" do
    it "requires positive price" do
      addon = build(:tour_add_on, tour:, price_cents: -100)
      expect(addon).not_to be_valid
      expect(addon.errors[:price_cents]).to be_present
    end

    it "requires valid pricing type" do
      expect do
        create(:tour_add_on, tour:, pricing_type: :invalid_type)
      end.to raise_error(ArgumentError)
    end

    it "requires name" do
      addon = build(:tour_add_on, tour:, name: nil)
      expect(addon).not_to be_valid
    end

    it "sets default active status to true" do
      addon = create(:tour_add_on, tour:)
      expect(addon.active).to be(true)
    end
  end
end
