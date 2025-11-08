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
FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "user-#{SecureRandom.hex(5)}@example.com" }
    password { "aaaabbbbccccdddd" }
    password_confirmation { password }
    role { "tourist" }

    trait :guide do
      role { "guide" }
      name { "Guide #{SecureRandom.hex(3)}" }
    end

    trait :tourist do
      role { "tourist" }
      name { "Tourist #{SecureRandom.hex(3)}" }
    end

    trait :admin do
      role { "admin" }
      name { "Admin #{SecureRandom.hex(3)}" }
    end
  end
end
