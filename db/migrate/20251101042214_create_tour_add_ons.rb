class CreateTourAddOns < ActiveRecord::Migration[8.0]
  def change
    create_table :tour_add_ons do |t|
      t.references :tour, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :addon_type, null: false, default: 0
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: "BRL"
      t.integer :pricing_type, null: false, default: 0
      t.integer :maximum_quantity
      t.boolean :active, null: false, default: true
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :tour_add_ons, %i[tour_id position]
    add_index :tour_add_ons, :active
  end
end
