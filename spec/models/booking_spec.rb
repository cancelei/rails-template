# == Schema Information
#
# Table name: bookings
#
#  id           :bigint           not null, primary key
#  booked_email :string           not null
#  booked_name  :string           not null
#  created_via  :string           default("guest_booking")
#  spots        :integer          default(1)
#  status       :integer          default("confirmed")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tour_id      :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_bookings_on_booked_email  (booked_email)
#  index_bookings_on_tour_id       (tour_id)
#  index_bookings_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (tour_id => tours.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Booking do
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:, capacity: 10, price_cents: 5000) }
  let(:booking) { create(:booking, tour:, user: tourist, spots: 2) }

  describe "associations" do
    it { is_expected.to belong_to(:tour).counter_cache(true) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one(:review).dependent(:destroy) }
    it { is_expected.to have_many(:booking_add_ons).dependent(:destroy) }
    it { is_expected.to have_many(:tour_add_ons).through(:booking_add_ons) }
  end

  describe "validations" do
    subject { booking }

    it { is_expected.to validate_presence_of(:booked_name) }
    it { is_expected.to validate_length_of(:booked_name).is_at_most(100) }
    it { is_expected.to validate_presence_of(:booked_email) }
    it { is_expected.to validate_presence_of(:spots) }
    it { is_expected.to validate_numericality_of(:spots).is_greater_than(0) }

    it "validates email format" do
      booking.booked_email = "invalid-email"
      expect(booking).not_to be_valid
      expect(booking.errors[:booked_email]).to be_present
    end

    it "allows valid email format" do
      booking.booked_email = "valid@example.com"
      expect(booking).to be_valid
    end
  end

  describe "enums" do
    subject(:booking_model) { described_class }

    it { expect(booking_model).to define_enum_for(:status).with_values(confirmed: 0, cancelled: 1) }

    it do
      expect(booking_model).to define_enum_for(:created_via)
        .with_values(guest_booking: "guest_booking", user_portal: "user_portal")
    end
  end

  describe "callbacks" do
    describe "#set_booked_details_from_user" do
      it "sets booked_name from user" do
        new_booking = build(:booking, tour:, user: tourist, booked_name: nil, booked_email: nil)
        new_booking.valid?
        expect(new_booking.booked_name).to eq(tourist.email)
      end

      it "sets booked_email from user" do
        new_booking = build(:booking, tour:, user: tourist, booked_name: nil, booked_email: nil)
        new_booking.valid?
        expect(new_booking.booked_email).to eq(tourist.email)
      end
    end
  end

  describe "#cancel!" do
    it "cancels a confirmed booking" do
      expect(booking.cancel!).to be true
      expect(booking.reload).to be_cancelled
    end

    it "returns false if already cancelled" do
      booking.update(status: :cancelled)
      expect(booking.cancel!).to be false
    end
  end

  describe "#tour_price" do
    it "calculates price based on tour price and spots" do
      expect(booking.tour_price).to eq(10_000) # 5000 * 2 spots
    end

    it "returns 0 if tour has no price" do
      tour.update(price_cents: nil)
      expect(booking.tour_price).to eq(0)
    end
  end

  describe "#add_ons_total" do
    it "returns 0 when no add-ons" do
      expect(booking.add_ons_total).to eq(0)
    end

    it "calculates total from booking add-ons" do
      tour_add_on = create(:tour_add_on, tour:, price_cents: 1000)
      create(:booking_add_on, booking:, tour_add_on:, quantity: 2, price_at_booking_cents: 1000)
      expect(booking.add_ons_total).to eq(2000)
    end
  end

  describe "#total_price_with_add_ons" do
    it "combines tour price and add-ons total" do
      tour_add_on = create(:tour_add_on, tour:, price_cents: 1000)
      create(:booking_add_on, booking:, tour_add_on:, quantity: 1, price_at_booking_cents: 1000)
      expect(booking.total_price_with_add_ons).to eq(11_000) # 10000 + 1000
    end
  end

  describe "#formatted_total_price" do
    it "formats price in USD" do
      expect(booking.formatted_total_price).to include("$")
      expect(booking.formatted_total_price).to include("100.00")
    end

    it "formats price in BRL" do
      tour.update(currency: "BRL")
      expect(booking.formatted_total_price).to include("R$")
    end
  end

  describe "custom validations" do
    describe "#spots_within_capacity" do
      it "is valid when spots are within capacity" do
        booking.spots = 5
        expect(booking).to be_valid
      end

      it "is invalid when spots exceed capacity" do
        booking.spots = 15
        expect(booking).not_to be_valid
        expect(booking.errors[:spots]).to include("exceeds tour capacity")
      end

      it "considers existing bookings" do
        create(:booking, tour:, spots: 8)
        booking.spots = 5
        expect(booking).not_to be_valid
      end
    end

    describe "#private_tour_booking_restrictions" do
      let(:private_tour) { create(:tour, :private_tour, guide:) }

      it "allows only one booking for private tours" do
        create(:booking, tour: private_tour, user: tourist)
        new_booking = build(:booking, tour: private_tour, user: create(:user, :tourist))
        expect(new_booking).not_to be_valid
      end
    end
  end
end
