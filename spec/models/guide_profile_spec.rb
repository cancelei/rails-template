# == Schema Information
#
# Table name: guide_profiles
#
#  id            :bigint           not null, primary key
#  bio           :text
#  languages     :string
#  rating_cached :float
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_guide_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe GuideProfile do
  let(:guide) { create(:user, :guide) }
  let(:guide_profile) { create(:guide_profile, user: guide) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_length_of(:bio).is_at_most(1000) }
    it { is_expected.to validate_length_of(:languages).is_at_most(100) }

    it "validates rating_cached is within range" do
      guide_profile.rating_cached = -1
      expect(guide_profile).not_to be_valid

      guide_profile.rating_cached = 6
      expect(guide_profile).not_to be_valid

      guide_profile.rating_cached = 3.5
      expect(guide_profile).to be_valid
    end

    it "allows nil rating_cached" do
      guide_profile.rating_cached = nil
      expect(guide_profile).to be_valid
    end

    it "is invalid with bio too long" do
      guide_profile.bio = "a" * 1001
      expect(guide_profile).not_to be_valid
    end

    it "is invalid with languages too long" do
      guide_profile.languages = "a" * 101
      expect(guide_profile).not_to be_valid
    end
  end

  describe "delegations" do
    it "delegates comments_count to comments" do
      create_list(:comment, 3, guide_profile:, user: create(:user, :tourist))
      expect(guide_profile.comments_count).to eq(3)
    end
  end

  describe "attributes" do
    it "can store bio" do
      guide_profile.bio = "Experienced tour guide with 10 years of experience"
      guide_profile.save
      expect(guide_profile.reload.bio).to eq("Experienced tour guide with 10 years of experience")
    end

    it "can store languages" do
      guide_profile.languages = "English, Spanish, French"
      guide_profile.save
      expect(guide_profile.reload.languages).to eq("English, Spanish, French")
    end

    it "can store rating_cached" do
      guide_profile.rating_cached = 4.5
      guide_profile.save
      expect(guide_profile.reload.rating_cached).to eq(4.5)
    end
  end
end
