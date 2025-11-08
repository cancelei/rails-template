# == Schema Information
#
# Table name: tours
#
#  id                     :bigint           not null, primary key
#  booking_deadline_hours :integer
#  bookings_count         :integer          default(0), not null
#  capacity               :integer          not null
#  currency               :string
#  current_headcount      :integer          default(0)
#  description            :text
#  ends_at                :datetime         not null
#  latitude               :float
#  location_name          :string
#  longitude              :float
#  price_cents            :integer
#  starts_at              :datetime         not null
#  status                 :integer          default("scheduled")
#  title                  :string           not null
#  tour_type              :integer          default("public_tour"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  guide_id               :bigint           not null
#
# Indexes
#
#  index_tours_on_guide_id   (guide_id)
#  index_tours_on_starts_at  (starts_at)
#  index_tours_on_status     (status)
#  index_tours_on_tour_type  (tour_type)
#
# Foreign Keys
#
#  fk_rails_...  (guide_id => users.id)
#
require "rails_helper"

RSpec.describe Tour do
  describe "validations" do
    subject(:tour) { build(:tour) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }
    it { is_expected.to validate_presence_of(:capacity) }

    context "when tour is a private_tour" do
      subject(:tour) { build(:tour, :private_tour) }

      it { is_expected.to validate_presence_of(:booking_deadline_hours) }
      it { is_expected.to validate_numericality_of(:booking_deadline_hours).only_integer.is_greater_than(0) }
    end

    context "when tour is a public_tour" do
      subject(:tour) { build(:tour, tour_type: :public_tour) }

      it { is_expected.not_to validate_presence_of(:booking_deadline_hours) }
    end
  end

  describe "#booking_deadline" do
    context "when tour is a private_tour" do
      let(:starts_at) { 2.days.from_now }
      let(:tour) { build(:tour, :private_tour, starts_at:, booking_deadline_hours: 24) }

      it "calculates deadline correctly" do
        expected_deadline = starts_at - 24.hours
        expect(tour.booking_deadline).to be_within(1.second).of(expected_deadline)
      end
    end

    context "when tour is a public_tour" do
      let(:tour) { build(:tour, tour_type: :public_tour) }

      it "returns nil" do
        expect(tour.booking_deadline).to be_nil
      end
    end

    context "when booking_deadline_hours is not set" do
      let(:tour) { build(:tour, :private_tour, booking_deadline_hours: nil) }

      it "returns nil" do
        expect(tour.booking_deadline).to be_nil
      end
    end
  end

  describe "#can_book?" do
    context "for private tours" do
      let(:tour) { create(:tour, :private_tour, starts_at: 2.days.from_now, booking_deadline_hours: 24) }

      it "returns true when before deadline and unbooked" do
        expect(tour.can_book?).to be true
      end

      it "returns false when deadline has passed" do
        tour.update!(booking_deadline_hours: 72)
        travel_to(25.hours.from_now) do
          expect(tour.can_book?).to be false
        end
      end

      it "returns false when already booked" do
        create(:booking, tour:, spots: 1, status: :confirmed)
        tour.reload
        expect(tour.can_book?).to be false
      end
    end

    context "for public tours" do
      let(:tour) { create(:tour, tour_type: :public_tour, starts_at: 2.days.from_now, capacity: 10) }

      it "returns true when there are available spots" do
        expect(tour.can_book?).to be true
      end

      it "returns false when fully booked" do
        create(:booking, tour:, spots: 10, status: :confirmed)
        tour.reload
        expect(tour.can_book?).to be false
      end
    end
  end

  describe "#booking_deadline_passed?" do
    context "for private tours" do
      let(:starts_at_time) { 3.days.from_now }
      let(:tour) { create(:tour, :private_tour, starts_at: starts_at_time, booking_deadline_hours: 48) }

      it "returns false when before deadline" do
        expect(tour.booking_deadline_passed?).to be false
      end

      it "returns true when after deadline" do
        # Deadline is 48 hours before start (3 days - 48 hours = 1 day from now)
        # Travel to after the deadline
        travel_to(starts_at_time - 47.hours) do
          expect(tour.booking_deadline_passed?).to be true
        end
      end
    end

    context "for public tours" do
      let(:tour) { create(:tour, tour_type: :public_tour) }

      it "returns false" do
        expect(tour.booking_deadline_passed?).to be false
      end
    end
  end

  describe "#booked_spots" do
    let(:tour) { create(:tour, capacity: 10) }

    it "returns 0 when no bookings" do
      expect(tour.booked_spots).to eq(0)
    end

    it "sums confirmed booking spots" do
      create(:booking, tour:, spots: 2, status: :confirmed)
      create(:booking, tour:, spots: 3, status: :confirmed)
      expect(tour.booked_spots).to eq(5)
    end

    it "ignores cancelled bookings" do
      create(:booking, tour:, spots: 2, status: :confirmed)
      create(:booking, tour:, spots: 3, status: :cancelled)
      expect(tour.booked_spots).to eq(2)
    end
  end

  describe "#available_spots" do
    let(:tour) { create(:tour, capacity: 10) }

    it "returns capacity when no bookings" do
      expect(tour.available_spots).to eq(10)
    end

    it "returns remaining spots" do
      create(:booking, tour:, spots: 6)
      expect(tour.available_spots).to eq(4)
    end
  end

  describe "#fully_booked?" do
    context "for public tours" do
      let(:tour) { create(:tour, capacity: 5) }

      it "returns false when spots available" do
        create(:booking, tour:, spots: 3)
        expect(tour.fully_booked?).to be false
      end

      it "returns true when no spots available" do
        create(:booking, tour:, spots: 5)
        expect(tour.fully_booked?).to be true
      end
    end

    context "for private tours" do
      let(:tour) { create(:tour, :private_tour) }

      it "returns false when unbooked" do
        expect(tour.fully_booked?).to be false
      end

      it "returns true when booked" do
        create(:booking, tour:, status: :confirmed)
        expect(tour.fully_booked?).to be true
      end
    end
  end

  describe "#past?" do
    it "returns true when tour has ended" do
      tour = build(:tour, ends_at: 1.day.ago)
      expect(tour.past?).to be true
    end

    it "returns false when tour hasn't ended" do
      tour = build(:tour, ends_at: 1.day.from_now)
      expect(tour.past?).to be false
    end
  end

  describe "#upcoming?" do
    it "returns true when tour hasn't started" do
      tour = build(:tour, starts_at: 1.day.from_now)
      expect(tour.upcoming?).to be true
    end

    it "returns false when tour has started" do
      tour = build(:tour, starts_at: 1.day.ago)
      expect(tour.upcoming?).to be false
    end
  end

  describe "#duration_minutes" do
    it "calculates duration in minutes" do
      tour = build(:tour, starts_at: Time.current, ends_at: 2.hours.from_now)
      expect(tour.duration_minutes).to eq(120)
    end

    it "returns nil when starts_at or ends_at is nil" do
      tour = build(:tour, starts_at: nil, ends_at: nil)
      expect(tour.duration_minutes).to be_nil
    end
  end

  describe "custom validations" do
    describe "#ends_after_starts" do
      it "is invalid when ends_at is before starts_at" do
        tour = build(:tour, starts_at: 2.days.from_now, ends_at: 1.day.from_now)
        expect(tour).not_to be_valid
        expect(tour.errors[:ends_at]).to include("must be after starts_at")
      end

      it "is invalid when ends_at equals starts_at" do
        time = 2.days.from_now
        tour = build(:tour, starts_at: time, ends_at: time)
        expect(tour).not_to be_valid
      end
    end
  end
end
