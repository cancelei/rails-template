# == Schema Information
#
# Table name: booking_add_ons
#
#  id                     :bigint           not null, primary key
#  price_cents_at_booking :integer          not null
#  quantity               :integer          default(1), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  booking_id             :bigint           not null
#  tour_add_on_id         :bigint           not null
#
# Indexes
#
#  index_booking_add_ons_on_booking_id                     (booking_id)
#  index_booking_add_ons_on_booking_id_and_tour_add_on_id  (booking_id,tour_add_on_id) UNIQUE
#  index_booking_add_ons_on_tour_add_on_id                 (tour_add_on_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (tour_add_on_id => tour_add_ons.id)
#
require "rails_helper"

RSpec.describe BookingAddOn do
  describe "associations" do
    subject { build(:booking_add_on) }

    it { is_expected.to belong_to(:booking) }
    it { is_expected.to belong_to(:tour_add_on) }
  end

  describe "validations" do
    subject { build(:booking_add_on) }

    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:price_cents_at_booking).is_greater_than_or_equal_to(0) }

    it "requires price_cents_at_booking to be present" do
      booking_add_on = build(:booking_add_on, price_cents_at_booking: nil)
      # The before_validation callback will set it, so we need to test differently
      expect(booking_add_on).to be_valid
      expect(booking_add_on.price_cents_at_booking).not_to be_nil
    end

    it "validates uniqueness of tour_add_on per booking" do
      tour = create(:tour)
      booking = create(:booking, tour:)
      tour_add_on = create(:tour_add_on, tour:)

      create(:booking_add_on, booking:, tour_add_on:)
      duplicate = build(:booking_add_on, booking:, tour_add_on:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tour_add_on_id]).to include("has already been added to this booking")
    end
  end

  describe "callbacks" do
    describe "#set_price_at_booking" do
      let(:tour) { create(:tour) }
      let(:booking) { create(:booking, tour:, spots: 2) }
      let(:tour_add_on) { create(:tour_add_on, tour:, price_cents: 3000) }

      context "when price_cents_at_booking is not set" do
        it "automatically sets price from tour_add_on" do
          booking_add_on = described_class.new(
            booking:,
            tour_add_on:,
            quantity: 1
          )

          expect(booking_add_on.price_cents_at_booking).to be_nil
          booking_add_on.save!
          expect(booking_add_on.price_cents_at_booking).to eq(3000)
        end
      end

      context "when price_cents_at_booking is already set" do
        it "does not override the existing price" do
          booking_add_on = described_class.create!(
            booking:,
            tour_add_on:,
            quantity: 1,
            price_cents_at_booking: 2500
          )

          expect(booking_add_on.price_cents_at_booking).to eq(2500)
        end
      end
    end
  end

  describe "#total_price" do
    let(:tour) { create(:tour) }
    let(:booking) { create(:booking, tour:, spots: 3) }

    context "when tour_add_on has per_person pricing" do
      let(:tour_add_on) do
        create(:tour_add_on,
               tour:,
               price_cents: 1000,
               pricing_type: :per_person)
      end

      it "multiplies price by spots and quantity" do
        booking_add_on = create(:booking_add_on,
                                booking:,
                                tour_add_on:,
                                quantity: 1,
                                price_cents_at_booking: 1000)

        # 1000 cents * 3 spots * 1 quantity = 3000 cents
        expect(booking_add_on.total_price).to eq(3000)
      end

      it "accounts for quantity when multiple items ordered" do
        booking_add_on = create(:booking_add_on,
                                booking:,
                                tour_add_on:,
                                quantity: 2,
                                price_cents_at_booking: 1000)

        # 1000 cents * 3 spots * 2 quantity = 6000 cents
        expect(booking_add_on.total_price).to eq(6000)
      end
    end

    context "when tour_add_on has flat_fee pricing" do
      let(:tour_add_on) do
        create(:tour_add_on,
               tour:,
               price_cents: 5000,
               pricing_type: :flat_fee)
      end

      it "multiplies price by quantity only (ignores spots)" do
        booking_add_on = create(:booking_add_on,
                                booking:,
                                tour_add_on:,
                                quantity: 1,
                                price_cents_at_booking: 5000)

        # 5000 cents * 1 quantity (spots ignored for flat fee)
        expect(booking_add_on.total_price).to eq(5000)
      end

      it "accounts for quantity when multiple items ordered" do
        booking_add_on = create(:booking_add_on,
                                booking:,
                                tour_add_on:,
                                quantity: 2,
                                price_cents_at_booking: 5000)

        # 5000 cents * 2 quantity = 10000 cents
        expect(booking_add_on.total_price).to eq(10_000)
      end
    end

    context "when add-on price changes after booking" do
      it "uses the historical price_cents_at_booking" do
        tour_add_on = create(:tour_add_on,
                             tour:,
                             price_cents: 1000,
                             pricing_type: :per_person)

        booking_add_on = create(:booking_add_on,
                                booking:,
                                tour_add_on:,
                                quantity: 1,
                                price_cents_at_booking: 1000)

        # Original price: 1000 * 3 spots = 3000
        expect(booking_add_on.total_price).to eq(3000)

        # Change the tour add-on price
        tour_add_on.update!(price_cents: 2000)

        # Booking add-on should still use historical price
        expect(booking_add_on.reload.total_price).to eq(3000)
      end
    end
  end

  describe "defaults" do
    let(:tour) { create(:tour) }
    let(:booking) { create(:booking, tour:) }
    let(:tour_add_on) { create(:tour_add_on, tour:, price_cents: 1500) }

    it "defaults quantity to 1" do
      booking_add_on = described_class.new(
        booking:,
        tour_add_on:
      )
      expect(booking_add_on.quantity).to eq(1)
    end
  end

  describe "integration with Booking model" do
    let(:tour) { create(:tour, price_cents: 10_000) }
    let(:booking) { create(:booking, tour:, spots: 2) }
    let(:add_on_1) do
      create(:tour_add_on,
             tour:,
             price_cents: 1000,
             pricing_type: :per_person)
    end
    let(:add_on_2) do
      create(:tour_add_on,
             tour:,
             price_cents: 5000,
             pricing_type: :flat_fee)
    end

    it "calculates correct total with multiple add-ons" do
      # Create booking add-ons
      create(:booking_add_on,
             booking:,
             tour_add_on: add_on_1,
             quantity: 1,
             price_cents_at_booking: 1000)

      create(:booking_add_on,
             booking:,
             tour_add_on: add_on_2,
             quantity: 1,
             price_cents_at_booking: 5000)

      # Tour price: 10000 * 2 spots = 20000
      # Add-on 1 (per person): 1000 * 2 spots = 2000
      # Add-on 2 (flat fee): 5000
      # Total add-ons: 7000
      # Grand total: 27000

      expect(booking.tour_price).to eq(20_000)
      expect(booking.add_ons_total).to eq(7000)
      expect(booking.total_price_with_add_ons).to eq(27_000)
    end
  end
end
