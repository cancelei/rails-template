# == Schema Information
#
# Table name: likes
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  comment_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_likes_on_comment_id  (comment_id)
#  index_likes_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (comment_id => comments.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Like do
  describe "associations" do
    it "belongs to user" do
      like = described_class.reflect_on_association(:user)
      expect(like.macro).to eq(:belongs_to)
    end

    it "belongs to comment with counter_cache" do
      like = described_class.reflect_on_association(:comment)
      expect(like.macro).to eq(:belongs_to)
      expect(like.options[:counter_cache]).to be_truthy
    end
  end

  describe "validations" do
    let(:user) { create(:user, role: :tourist) }
    let(:guide) { create(:user, role: :guide) }
    let(:guide_profile) { create(:guide_profile, user: guide) }
    let(:comment) { create(:comment, user:, guide_profile:) }

    it "is valid with valid attributes" do
      like = described_class.new(user:, comment:)
      expect(like).to be_valid
    end

    it "validates presence of user" do
      like = described_class.new(comment:)
      expect(like).not_to be_valid
      expect(like.errors[:user]).to include("must exist")
    end

    it "validates presence of comment" do
      like = described_class.new(user:)
      expect(like).not_to be_valid
      expect(like.errors[:comment]).to include("must exist")
    end

    it "validates uniqueness of user scoped to comment" do
      described_class.create!(user:, comment:)
      duplicate = described_class.new(user:, comment:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user]).to include("can only like a comment once")
    end

    it "allows the same user to like different comments" do
      another_comment = create(:comment, user:, guide_profile:)

      described_class.create!(user:, comment:)
      like2 = described_class.new(user:, comment: another_comment)

      expect(like2).to be_valid
    end

    it "allows different users to like the same comment" do
      another_user = create(:user, role: :tourist, email: "another@example.com")

      described_class.create!(user:, comment:)
      like2 = described_class.new(user: another_user, comment:)

      expect(like2).to be_valid
    end
  end

  describe "counter_cache" do
    let(:user) { create(:user, role: :tourist) }
    let(:guide) { create(:user, role: :guide) }
    let(:guide_profile) { create(:guide_profile, user: guide) }
    let(:comment) { create(:comment, user:, guide_profile:) }

    it "increments likes_count when a like is created" do
      # Initialize likes_count to 0 if nil
      comment.update_column(:likes_count, 0) if comment.likes_count.nil?

      expect do
        described_class.create!(user:, comment:)
        comment.reload
      end.to change(comment, :likes_count).from(0).to(1)
    end

    it "decrements likes_count when a like is destroyed" do
      like = described_class.create!(user:, comment:)
      comment.reload

      expect do
        like.destroy
        comment.reload
      end.to change(comment, :likes_count).from(1).to(0)
    end

    it "correctly counts multiple likes" do
      user2 = create(:user, role: :tourist, email: "user2@example.com")
      user3 = create(:user, role: :tourist, email: "user3@example.com")

      described_class.create!(user:, comment:)
      described_class.create!(user: user2, comment:)
      described_class.create!(user: user3, comment:)

      comment.reload
      expect(comment.likes_count).to eq(3)
    end
  end

  describe "cascade deletion" do
    let(:user) { create(:user, role: :tourist) }
    let(:guide) { create(:user, role: :guide) }
    let(:guide_profile) { create(:guide_profile, user: guide) }
    let(:comment) { create(:comment, user:, guide_profile:) }

    it "deletes like when comment is deleted" do
      like = described_class.create!(user:, comment:)

      expect do
        comment.destroy
      end.to change(described_class, :count).by(-1)

      expect(described_class.find_by(id: like.id)).to be_nil
    end

    it "deletes like when user is deleted" do
      like = described_class.create!(user:, comment:)

      expect do
        user.destroy
      end.to change(described_class, :count).by(-1)

      expect(described_class.find_by(id: like.id)).to be_nil
    end
  end
end
