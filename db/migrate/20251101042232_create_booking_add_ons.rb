class CreateBookingAddOns < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_add_ons do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :tour_add_on, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :price_cents_at_booking, null: false

      t.timestamps
    end

    add_index :booking_add_ons, %i[booking_id tour_add_on_id], unique: true
  end
end
