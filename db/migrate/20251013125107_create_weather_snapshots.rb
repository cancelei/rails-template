class CreateWeatherSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_snapshots do |t|
      t.references :tour, null: false, foreign_key: true
      t.date :forecast_date, null: false
      t.float :min_temp
      t.float :max_temp
      t.string :description
      t.string :icon
      t.float :pop
      t.float :wind_speed
      t.text :alerts_json

      t.timestamps
    end
    add_index :weather_snapshots, %i[tour_id forecast_date], unique: true
  end
end
