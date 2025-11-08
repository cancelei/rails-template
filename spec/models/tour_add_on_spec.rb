# == Schema Information
#
# Table name: tour_add_ons
#
#  id               :bigint           not null, primary key
#  active           :boolean          default(TRUE), not null
#  addon_type       :integer          default("transportation"), not null
#  currency         :string           default("BRL"), not null
#  description      :text
#  maximum_quantity :integer
#  name             :string           not null
#  position         :integer          default(0)
#  price_cents      :integer          not null
#  pricing_type     :integer          default("per_person"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  tour_id          :bigint           not null
#
# Indexes
#
#  index_tour_add_ons_on_active                (active)
#  index_tour_add_ons_on_tour_id               (tour_id)
#  index_tour_add_ons_on_tour_id_and_position  (tour_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (tour_id => tours.id)
#
require "rails_helper"

RSpec.describe TourAddOn do
  describe "associations" do
    it { is_expected.to belong_to(:tour) }
    it { is_expected.to have_many(:booking_add_ons).dependent(:destroy) }
    it { is_expected.to have_many(:bookings).through(:booking_add_ons) }
  end

  describe "validations" do
    subject { build(:tour_add_on) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
    it { is_expected.to validate_presence_of(:price_cents) }
    it { is_expected.to validate_numericality_of(:price_cents).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }

    it "validates maximum_quantity when present" do
      tour = create(:tour)
      add_on = build(:tour_add_on, tour:, maximum_quantity: 0)
      expect(add_on).not_to be_valid
      expect(add_on.errors[:maximum_quantity]).to include("must be greater than 0")
    end
  end

  describe "enums" do
    it "defines addon_type enum" do
      expect(described_class.addon_types).to eq({
        "transportation" => 0,
        "food_beverage" => 1,
        "photography" => 2,
        "equipment" => 3
      })
    end

    it "defines pricing_type enum" do
      expect(described_class.pricing_types).to eq({
        "per_person" => 0,
        "flat_fee" => 1
      })
    end
  end

  describe "scopes" do
    let(:tour) { create(:tour) }
    let!(:active_add_on) { create(:tour_add_on, tour:, active: true, position: 1) }
    let!(:inactive_add_on) { create(:tour_add_on, tour:, active: false, position: 2) }
    let!(:first_position) { create(:tour_add_on, tour:, active: true, position: 0) }

    describe ".active" do
      it "returns only active add-ons" do
        expect(tour.tour_add_ons.active).to include(active_add_on, first_position)
        expect(tour.tour_add_ons.active).not_to include(inactive_add_on)
      end
    end

    describe ".by_position" do
      it "orders add-ons by position" do
        expect(tour.tour_add_ons.by_position).to eq([first_position, active_add_on, inactive_add_on])
      end
    end
  end

  describe "#formatted_price" do
    let(:tour) { create(:tour, currency: "BRL") }

    context "when pricing_type is per_person" do
      let(:add_on) do
        create(:tour_add_on,
               tour:,
               price_cents: 2500,
               pricing_type: :per_person,
               currency: "BRL")
      end

      it "returns formatted price with 'per person' suffix" do
        expect(add_on.formatted_price).to eq("R$25.00 per person")
      end
    end

    context "when pricing_type is flat_fee" do
      let(:add_on) do
        create(:tour_add_on,
               tour:,
               price_cents: 5000,
               pricing_type: :flat_fee,
               currency: "BRL")
      end

      it "returns formatted price without suffix" do
        expect(add_on.formatted_price).to eq("R$50.00")
      end
    end

    context "with USD currency" do
      let(:add_on) do
        create(:tour_add_on,
               tour:,
               price_cents: 3000,
               pricing_type: :flat_fee,
               currency: "USD")
      end

      it "returns formatted price with USD symbol" do
        expect(add_on.formatted_price).to eq("$30.00")
      end
    end
  end

  describe "#total_price" do
    let(:tour) { create(:tour) }

    context "when pricing_type is per_person" do
      let(:add_on) do
        create(:tour_add_on,
               tour:,
               price_cents: 1000,
               pricing_type: :per_person)
      end

      it "multiplies price by number of guests" do
        expect(add_on.total_price(1)).to eq(1000)
        expect(add_on.total_price(3)).to eq(3000)
        expect(add_on.total_price(5)).to eq(5000)
      end

      it "defaults to 1 guest when not specified" do
        expect(add_on.total_price).to eq(1000)
      end
    end

    context "when pricing_type is flat_fee" do
      let(:add_on) do
        create(:tour_add_on,
               tour:,
               price_cents: 5000,
               pricing_type: :flat_fee)
      end

      it "returns the same price regardless of guests" do
        expect(add_on.total_price(1)).to eq(5000)
        expect(add_on.total_price(3)).to eq(5000)
        expect(add_on.total_price(10)).to eq(5000)
      end
    end
  end

  describe "#addon_type_icon" do
    let(:tour) { create(:tour) }

    it "returns correct icon for transportation" do
      add_on = create(:tour_add_on, tour:, addon_type: :transportation)
      expect(add_on.addon_type_icon).to eq("🚗")
    end

    it "returns correct icon for food_beverage" do
      add_on = create(:tour_add_on, tour:, addon_type: :food_beverage)
      expect(add_on.addon_type_icon).to eq("🍽️")
    end

    it "returns correct icon for photography" do
      add_on = create(:tour_add_on, tour:, addon_type: :photography)
      expect(add_on.addon_type_icon).to eq("📸")
    end

    it "returns correct icon for equipment" do
      add_on = create(:tour_add_on, tour:, addon_type: :equipment)
      expect(add_on.addon_type_icon).to eq("🎒")
    end
  end

  describe "#currency_symbol" do
    let(:tour) { create(:tour) }

    it "returns R$ for BRL" do
      add_on = create(:tour_add_on, tour:, currency: "BRL")
      expect(add_on.currency_symbol).to eq("R$")
    end

    it "returns $ for USD" do
      add_on = create(:tour_add_on, tour:, currency: "USD")
      expect(add_on.currency_symbol).to eq("$")
    end

    it "returns € for EUR" do
      add_on = create(:tour_add_on, tour:, currency: "EUR")
      expect(add_on.currency_symbol).to eq("€")
    end

    it "returns currency code for unknown currencies" do
      add_on = create(:tour_add_on, tour:, currency: "GBP")
      expect(add_on.currency_symbol).to eq("GBP")
    end
  end

  describe "defaults" do
    let(:tour) { create(:tour) }
    let(:add_on) { described_class.new(tour:, name: "Test Add-on", price_cents: 1000) }

    it "defaults active to true" do
      expect(add_on.active).to be true
    end

    it "defaults position to 0" do
      expect(add_on.position).to eq(0)
    end

    it "defaults addon_type to transportation" do
      expect(add_on.addon_type).to eq("transportation")
    end

    it "defaults pricing_type to per_person" do
      expect(add_on.pricing_type).to eq("per_person")
    end

    it "defaults currency to BRL" do
      expect(add_on.currency).to eq("BRL")
    end
  end
end
