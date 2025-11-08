require "rails_helper"

RSpec.describe TourPolicy do
  subject(:policy) { described_class }

  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:other_guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:) }

  permissions :show? do
    it "allows anyone to view tours" do
      expect(policy).to permit(nil, tour)
      expect(policy).to permit(tourist, tour)
      expect(policy).to permit(guide, tour)
      expect(policy).to permit(admin, tour)
    end
  end

  permissions :update?, :edit? do
    it "allows admin to update any tour" do
      expect(policy).to permit(admin, tour)
    end

    it "allows guide to update their own tour" do
      expect(policy).to permit(guide, tour)
    end

    it "denies other guides from updating the tour" do
      expect(policy).not_to permit(other_guide, tour)
    end

    it "denies tourists from updating tours" do
      expect(policy).not_to permit(tourist, tour)
    end

    it "denies unauthenticated users from updating tours" do
      expect(policy).not_to permit(nil, tour)
    end
  end

  permissions :destroy? do
    it "allows admin to destroy any tour" do
      expect(policy).to permit(admin, tour)
    end

    it "allows guide to destroy their own tour" do
      expect(policy).to permit(guide, tour)
    end

    it "denies other guides from destroying the tour" do
      expect(policy).not_to permit(other_guide, tour)
    end

    it "denies tourists from destroying tours" do
      expect(policy).not_to permit(tourist, tour)
    end

    it "denies unauthenticated users from destroying tours" do
      expect(policy).not_to permit(nil, tour)
    end
  end

  permissions :cancel? do
    it "allows admin to cancel any tour" do
      expect(policy).to permit(admin, tour)
    end

    it "allows guide to cancel their own tour" do
      expect(policy).to permit(guide, tour)
    end

    it "denies other guides from cancelling the tour" do
      expect(policy).not_to permit(other_guide, tour)
    end

    it "denies tourists from cancelling tours" do
      expect(policy).not_to permit(tourist, tour)
    end

    it "denies unauthenticated users from cancelling tours" do
      expect(policy).not_to permit(nil, tour)
    end
  end

  describe "Scope" do
    let!(:guide_tour) { create(:tour, guide:) }
    let!(:other_guide_tour) { create(:tour, guide: other_guide) }

    it "returns all tours for admin" do
      resolved_scope = TourPolicy::Scope.new(admin, Tour.all).resolve
      expect(resolved_scope).to include(guide_tour, other_guide_tour)
    end

    it "returns only guide's tours for guide users" do
      resolved_scope = TourPolicy::Scope.new(guide, Tour.all).resolve
      expect(resolved_scope).to include(guide_tour)
      expect(resolved_scope).not_to include(other_guide_tour)
    end

    it "returns all tours for tourists" do
      resolved_scope = TourPolicy::Scope.new(tourist, Tour.all).resolve
      expect(resolved_scope).to include(guide_tour, other_guide_tour)
    end

    it "returns all tours for unauthenticated users" do
      resolved_scope = TourPolicy::Scope.new(nil, Tour.all).resolve
      expect(resolved_scope).to include(guide_tour, other_guide_tour)
    end
  end
end
