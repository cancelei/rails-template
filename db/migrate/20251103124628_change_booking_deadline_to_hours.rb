class ChangeBookingDeadlineToHours < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Remove the old datetime column
    safety_assured { remove_column :tours, :booking_deadline, :datetime }

    # Add new integer column for storing hours before tour start
    add_column :tours, :booking_deadline_hours, :integer
  end

  def down
    # Remove the new integer column
    remove_column :tours, :booking_deadline_hours, :integer

    # Add back the old datetime column
    add_column :tours, :booking_deadline, :datetime
  end
end
