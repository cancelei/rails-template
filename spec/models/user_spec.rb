# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_login_at          :datetime
#  locked_at              :datetime
#  name                   :string
#  phone                  :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("tourist")
#  session_token          :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_role                  (role)
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
require "rails_helper"

RSpec.describe User do
  describe "associations" do
    it { is_expected.to have_one(:guide_profile).dependent(:destroy) }
    it { is_expected.to have_many(:tours).dependent(:destroy) }
    it { is_expected.to have_many(:bookings).dependent(:destroy) }
    it { is_expected.to have_many(:reviews).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    it "validates name presence on create" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(tourist: "tourist", guide: "guide", admin: "admin") }
  end

  describe "User Factory" do
    it "creates valid users" do
      expect(FactoryBot.build(:user)).to be_valid
    end

    it "creates valid tourist" do
      expect(build(:user, :tourist)).to be_valid
    end

    it "creates valid guide" do
      expect(build(:user, :guide)).to be_valid
    end

    it "creates valid admin" do
      expect(build(:user, :admin)).to be_valid
    end
  end

  describe "callbacks" do
    describe "#create_guide_profile_if_guide" do
      it "creates guide profile for guide users" do
        guide = create(:user, :guide)
        expect(guide.guide_profile).to be_present
      end

      it "does not create guide profile for tourist users" do
        tourist = create(:user, :tourist)
        expect(tourist.guide_profile).to be_nil
      end

      it "does not create guide profile for admin users" do
        admin = create(:user, :admin)
        expect(admin.guide_profile).to be_nil
      end
    end
  end

  describe "#has_booking_with_guide?" do
    let(:tourist) { create(:user, :tourist) }
    let(:guide) { create(:user, :guide) }
    let(:tour) { create(:tour, guide:) }

    it "returns true when user has confirmed booking with guide" do
      create(:booking, user: tourist, tour:, status: :confirmed)
      expect(tourist.has_booking_with_guide?(guide)).to be true
    end

    it "returns false when user has no bookings with guide" do
      expect(tourist.has_booking_with_guide?(guide)).to be false
    end

    it "returns false when booking is cancelled" do
      create(:booking, user: tourist, tour:, status: :cancelled)
      expect(tourist.has_booking_with_guide?(guide)).to be false
    end

    it "returns false when guide_user is nil" do
      expect(tourist.has_booking_with_guide?(nil)).to be false
    end

    it "returns false when guide_user is not a guide" do
      other_tourist = create(:user, :tourist)
      expect(tourist.has_booking_with_guide?(other_tourist)).to be false
    end
  end

  describe "#booking_stats_with_guide" do
    let(:tourist) { create(:user, :tourist) }
    let(:guide) { create(:user, :guide) }
    let(:tour) { create(:tour, guide:) }

    it "returns nil when guide_user is nil" do
      expect(tourist.booking_stats_with_guide(nil)).to be_nil
    end

    it "returns nil when guide_user is not a guide" do
      other_tourist = create(:user, :tourist)
      expect(tourist.booking_stats_with_guide(other_tourist)).to be_nil
    end

    it "returns booking statistics" do
      create(:booking, user: tourist, tour:, status: :confirmed, spots: 2)
      stats = tourist.booking_stats_with_guide(guide)

      expect(stats).to be_present
      expect(stats[:total_bookings]).to eq(1)
      expect(stats[:total_spots]).to eq(2)
    end
  end

  it "is valid when created with valid attributes" do
    valid_password = "aaaabbbbccccdddd"
    user = described_class.new(name: "Jean-Luc Picard",
                               email: "picard@uss1701d.com",
                               password: valid_password,
                               password_confirmation: valid_password)
    expect(user).to be_valid
  end
end
