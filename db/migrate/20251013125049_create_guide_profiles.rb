class CreateGuideProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :guide_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.text :bio
      t.string :languages
      t.float :rating_cached

      t.timestamps
    end
  end
end
