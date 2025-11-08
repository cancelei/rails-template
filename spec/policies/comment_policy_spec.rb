require "rails_helper"

RSpec.describe CommentPolicy do
  subject(:policy) { described_class }

  let(:guide) { create(:user, :guide) }
  let(:guide_profile) { create(:guide_profile, user: guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:other_tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:) }
  let(:comment) { build(:comment, user: tourist, guide_profile:) }

  permissions :create? do
    context "when user has booking with guide" do
      before do
        create(:booking, user: tourist, tour:, status: :confirmed)
      end

      it "allows tourist to create comment" do
        expect(policy).to permit(tourist, comment)
      end
    end

    context "when user has no booking with guide" do
      it "denies tourist from creating comment" do
        expect(policy).not_to permit(tourist, comment)
      end
    end

    context "when user has cancelled booking" do
      before do
        create(:booking, user: tourist, tour:, status: :cancelled)
      end

      it "denies tourist from creating comment" do
        expect(policy).not_to permit(tourist, comment)
      end
    end

    it "denies unauthenticated users from creating comments" do
      expect(policy).not_to permit(nil, comment)
    end
  end

  permissions :toggle_like? do
    let(:saved_comment) { create(:comment, user: tourist, guide_profile:) }

    it "allows authenticated users to toggle like" do
      expect(policy).to permit(tourist, saved_comment)
      expect(policy).to permit(guide, saved_comment)
      expect(policy).to permit(other_tourist, saved_comment)
    end

    it "denies unauthenticated users from toggling like" do
      expect(policy).not_to permit(nil, saved_comment)
    end
  end
end
