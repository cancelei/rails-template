class CreateTours < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    create_table :tours do |t|
      t.references :guide, null: false
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0
      t.integer :capacity, null: false
      t.integer :price_cents
      t.string :currency
      t.string :location_name
      t.float :latitude
      t.float :longitude
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :cover_image_url
      t.integer :current_headcount, default: 0

      t.timestamps
    end
    add_foreign_key :tours, :users, column: :guide_id, validate: false
    add_index :tours, :status
    add_index :tours, :starts_at
  end
end
