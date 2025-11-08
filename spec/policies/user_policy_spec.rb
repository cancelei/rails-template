require "rails_helper"

RSpec.describe UserPolicy do
  subject(:policy) { described_class }

  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:other_tourist) { create(:user, :tourist) }

  permissions :index? do
    it "allows admin to view user index" do
      expect(policy).to permit(admin, User)
    end

    it "denies guides from viewing user index" do
      expect(policy).not_to permit(guide, User)
    end

    it "denies tourists from viewing user index" do
      expect(policy).not_to permit(tourist, User)
    end
  end

  permissions :show? do
    it "allows admin to view any user" do
      expect(policy).to permit(admin, tourist)
      expect(policy).to permit(admin, guide)
    end

    it "allows user to view their own profile" do
      expect(policy).to permit(tourist, tourist)
      expect(policy).to permit(guide, guide)
    end

    it "denies user from viewing other users" do
      expect(policy).not_to permit(tourist, other_tourist)
      expect(policy).not_to permit(guide, tourist)
    end
  end

  permissions :update?, :edit? do
    it "allows admin to update any user" do
      expect(policy).to permit(admin, tourist)
      expect(policy).to permit(admin, guide)
    end

    it "allows user to update their own profile" do
      expect(policy).to permit(tourist, tourist)
      expect(policy).to permit(guide, guide)
    end

    it "denies user from updating other users" do
      expect(policy).not_to permit(tourist, other_tourist)
      expect(policy).not_to permit(guide, tourist)
    end
  end

  permissions :destroy? do
    it "allows admin to destroy any user" do
      expect(policy).to permit(admin, tourist)
      expect(policy).to permit(admin, guide)
    end

    it "denies guides from destroying users" do
      expect(policy).not_to permit(guide, tourist)
      expect(policy).not_to permit(guide, guide)
    end

    it "denies tourists from destroying users" do
      expect(policy).not_to permit(tourist, other_tourist)
      expect(policy).not_to permit(tourist, tourist)
    end
  end

  describe "Scope" do
    let!(:user1) { create(:user, :tourist) }
    let!(:user2) { create(:user, :guide) }

    it "returns all users for admin" do
      resolved_scope = UserPolicy::Scope.new(admin, User.all).resolve
      expect(resolved_scope.count).to be >= 2
    end

    it "returns only current user for non-admin users" do
      resolved_scope = UserPolicy::Scope.new(tourist, User.all).resolve
      expect(resolved_scope).to include(tourist)
      expect(resolved_scope).not_to include(user1, user2)
    end
  end
end
