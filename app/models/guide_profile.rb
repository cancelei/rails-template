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
class GuideProfile < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :bio, length: { maximum: 1000 }
  validates :languages, length: { maximum: 100 }
  validates :rating_cached, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true

  delegate :count, to: :comments, prefix: true
end
