class AddTourTypeAndBookingDeadlineToTours < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :tours, :tour_type, :integer, default: 0, null: false
    add_column :tours, :booking_deadline, :datetime
    add_index :tours, :tour_type, algorithm: :concurrently
  end
end
