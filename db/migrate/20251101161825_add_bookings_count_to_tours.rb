class AddBookingsCountToTours < ActiveRecord::Migration[8.0]
  def change
    add_column :tours, :bookings_count, :integer, default: 0, null: false

    # Reset counter cache for existing records
    reversible do |dir|
      dir.up do
        Tour.find_each do |tour|
          Tour.reset_counters(tour.id, :bookings)
        end
      end
    end
  end
end
