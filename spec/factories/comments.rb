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
FactoryBot.define do
  factory :comment do
    content { "This is a great guide! Had an amazing experience on the tour." }
    user factory: %i[user], role: "tourist"
    guide_profile
  end
end
