class RemoveCoverImageUrlFromTours < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :tours, :cover_image_url, :string }
  end
end
