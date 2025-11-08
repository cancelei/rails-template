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
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :guide_profile
  has_many :likes, dependent: :destroy

  validates :content, presence: true, length: { minimum: 10, maximum: 1000 }

  def liked_by?(user)
    likes.exists?(user:)
  end
end
