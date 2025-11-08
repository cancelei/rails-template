# == Schema Information
#
# Table name: comments
#
#  id               :bigint           not null, primary key
#  content          :text
#  likes_count      :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  guide_profile_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_comments_on_guide_profile_id  (guide_profile_id)
#  index_comments_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (guide_profile_id => guide_profiles.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Comment do
  let(:guide) { create(:user, :guide) }
  let(:guide_profile) { create(:guide_profile, user: guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:comment) { create(:comment, user: tourist, guide_profile:) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:guide_profile) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
  end

  describe "validations" do
    subject { comment }

    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_length_of(:content).is_at_least(10).is_at_most(1000) }

    it "is invalid with short content" do
      comment.content = "Too short"
      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to be_present
    end

    it "is invalid with long content" do
      comment.content = "a" * 1001
      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to be_present
    end

    it "is valid with appropriate length content" do
      comment.content = "This is a valid comment with appropriate length for testing purposes."
      expect(comment).to be_valid
    end
  end

  describe "#liked_by?" do
    it "returns true when user has liked the comment" do
      create(:like, user: tourist, comment:)
      expect(comment.liked_by?(tourist)).to be true
    end

    it "returns false when user has not liked the comment" do
      expect(comment.liked_by?(tourist)).to be false
    end

    it "returns false for different user" do
      other_user = create(:user, :tourist)
      create(:like, user: tourist, comment:)
      expect(comment.liked_by?(other_user)).to be false
    end
  end

  describe "likes_count" do
    it "defaults to 0" do
      new_comment = create(:comment, user: tourist, guide_profile:)
      expect(new_comment.likes_count).to eq(0)
    end

    it "tracks number of likes" do
      create_list(:like, 3, comment:)
      expect(comment.reload.likes_count).to eq(3)
    end
  end
end
