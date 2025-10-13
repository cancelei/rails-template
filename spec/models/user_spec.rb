# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  locked_at              :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  session_token          :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
require "rails_helper"

RSpec.describe User do
  describe "User Factory" do
    it "creates valid users" do
      expect(FactoryBot.build(:user)).to be_valid
    end
  end

  it "is valid when created with valid attributes" do
    valid_password = "aaaabbbbccccdddd"
    user = described_class.new(email: "picard@uss1701d.com",
                               password: valid_password,
                               password_confirmation: valid_password)
    expect(user).to be_valid
  end
end
