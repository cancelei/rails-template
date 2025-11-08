require "rails_helper"

RSpec.describe GuideProfilePolicy do
  subject(:policy) { described_class }

  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:other_guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:guide_profile) { create(:guide_profile, user: guide) }

  permissions :update?, :edit? do
    it "allows admin to update any guide profile" do
      expect(policy).to permit(admin, guide_profile)
    end

    it "allows guide to update their own profile" do
      expect(policy).to permit(guide, guide_profile)
    end

    it "denies other guides from updating the profile" do
      expect(policy).not_to permit(other_guide, guide_profile)
    end

    it "denies tourists from updating guide profiles" do
      expect(policy).not_to permit(tourist, guide_profile)
    end

    it "denies unauthenticated users from updating guide profiles" do
      expect(policy).not_to permit(nil, guide_profile)
    end
  end

  permissions :destroy? do
    it "allows admin to destroy any guide profile" do
      expect(policy).to permit(admin, guide_profile)
    end

    it "allows guide to destroy their own profile" do
      expect(policy).to permit(guide, guide_profile)
    end

    it "denies other guides from destroying the profile" do
      expect(policy).not_to permit(other_guide, guide_profile)
    end

    it "denies tourists from destroying guide profiles" do
      expect(policy).not_to permit(tourist, guide_profile)
    end
  end

  describe "Scope" do
    let!(:guide_profile1) { create(:guide_profile, user: guide) }
    let!(:guide_profile2) { create(:guide_profile, user: other_guide) }

    it "returns all guide profiles for admin" do
      resolved_scope = GuideProfilePolicy::Scope.new(admin, GuideProfile.all).resolve
      expect(resolved_scope).to include(guide_profile1, guide_profile2)
    end

    it "returns only user's profile for guide users" do
      resolved_scope = GuideProfilePolicy::Scope.new(guide, GuideProfile.all).resolve
      expect(resolved_scope).to include(guide_profile1)
      expect(resolved_scope).not_to include(guide_profile2)
    end

    it "returns only user's profile for other users" do
      resolved_scope = GuideProfilePolicy::Scope.new(tourist, GuideProfile.all).resolve
      expect(resolved_scope).to be_empty
    end
  end
end
