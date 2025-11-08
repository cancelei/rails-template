require "rails_helper"

RSpec.describe BookingPolicy do
  subject(:policy) { described_class }

  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:other_tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:) }
  let(:booking) { create(:booking, tour:, user: tourist) }

  permissions :create? do
    it "allows authenticated users to create bookings" do
      expect(policy).to permit(tourist, Booking)
      expect(policy).to permit(guide, Booking)
      expect(policy).to permit(admin, Booking)
    end

    it "denies unauthenticated users from creating bookings" do
      expect(policy).not_to permit(nil, Booking)
    end
  end

  permissions :update?, :edit? do
    it "allows admin to update any booking" do
      expect(policy).to permit(admin, booking)
    end

    it "allows tourist to update their own booking" do
      expect(policy).to permit(tourist, booking)
    end

    it "denies other tourists from updating the booking" do
      expect(policy).not_to permit(other_tourist, booking)
    end

    it "denies guides from updating bookings" do
      expect(policy).not_to permit(guide, booking)
    end

    it "denies unauthenticated users from updating bookings" do
      expect(policy).not_to permit(nil, booking)
    end
  end

  permissions :destroy? do
    it "allows admin to destroy any booking" do
      expect(policy).to permit(admin, booking)
    end

    it "allows tourist to destroy their own booking" do
      expect(policy).to permit(tourist, booking)
    end

    it "denies other tourists from destroying the booking" do
      expect(policy).not_to permit(other_tourist, booking)
    end

    it "denies guides from destroying bookings" do
      expect(policy).not_to permit(guide, booking)
    end
  end

  permissions :cancel? do
    it "allows admin to cancel any booking" do
      expect(policy).to permit(admin, booking)
    end

    it "allows tourist to cancel their own booking" do
      expect(policy).to permit(tourist, booking)
    end

    it "allows guide to cancel bookings for their tours" do
      expect(policy).to permit(guide, booking)
    end

    it "denies other tourists from cancelling the booking" do
      expect(policy).not_to permit(other_tourist, booking)
    end
  end

  permissions :manage? do
    it "allows anyone to manage via magic link" do
      expect(policy).to permit(nil, booking)
      expect(policy).to permit(tourist, booking)
      expect(policy).to permit(guide, booking)
      expect(policy).to permit(admin, booking)
    end
  end

  permissions :review? do
    it "allows anyone to review via magic link" do
      expect(policy).to permit(nil, booking)
      expect(policy).to permit(tourist, booking)
      expect(policy).to permit(guide, booking)
      expect(policy).to permit(admin, booking)
    end
  end

  describe "Scope" do
    let!(:tourist_booking) { create(:booking, tour:, user: tourist) }
    let!(:other_tourist_booking) { create(:booking, tour:, user: other_tourist) }
    let!(:guide_tour_booking) { create(:booking, tour:, user: create(:user, :tourist)) }

    it "returns all bookings for admin" do
      resolved_scope = BookingPolicy::Scope.new(admin, Booking.all).resolve
      expect(resolved_scope).to include(tourist_booking, other_tourist_booking, guide_tour_booking)
    end

    it "returns only guide's tour bookings for guide users" do
      resolved_scope = BookingPolicy::Scope.new(guide, Booking.all).resolve
      expect(resolved_scope).to include(tourist_booking, other_tourist_booking, guide_tour_booking)
    end

    it "returns only user's bookings for tourists" do
      resolved_scope = BookingPolicy::Scope.new(tourist, Booking.all).resolve
      expect(resolved_scope).to include(tourist_booking)
      expect(resolved_scope).not_to include(other_tourist_booking)
    end
  end
end
