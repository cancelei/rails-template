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
FactoryBot.define do
  factory :guide_profile do
    user { nil }
    bio { "MyText" }
    languages { "MyString" }
    rating_cached { 1.5 }
  end
end
