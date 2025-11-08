class ChangeDefaultValueForLikesCount < ActiveRecord::Migration[8.0]
  def change
    change_column_default :comments, :likes_count, from: nil, to: 0

    # Update existing records that have nil likes_count
    reversible do |dir|
      dir.up do
        Comment.where(likes_count: nil).update_all(likes_count: 0)
      end
    end
  end
end
