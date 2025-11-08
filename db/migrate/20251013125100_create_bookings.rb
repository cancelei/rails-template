class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :tour, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :spots, default: 1
      t.integer :status, default: 0
      t.string :booked_email, null: false
      t.string :booked_name, null: false
      t.string :created_via, default: "guest_booking"

      t.timestamps
    end
    add_index :bookings, :booked_email
  end
end
