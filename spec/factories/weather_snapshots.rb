# == Schema Information
#
# Table name: weather_snapshots
#
#  id            :bigint           not null, primary key
#  alerts_json   :text
#  description   :string
#  forecast_date :date             not null
#  icon          :string
#  max_temp      :float
#  min_temp      :float
#  pop           :float
#  wind_speed    :float
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tour_id       :bigint           not null
#
# Indexes
#
#  index_weather_snapshots_on_tour_id                    (tour_id)
#  index_weather_snapshots_on_tour_id_and_forecast_date  (tour_id,forecast_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tour_id => tours.id)
#
FactoryBot.define do
  factory :weather_snapshot do
    tour { nil }
    forecast_date { "2025-10-13" }
    min_temp { 1.5 }
    max_temp { 1.5 }
    description { "MyString" }
    icon { "MyString" }
    pop { 1.5 }
    wind_speed { 1.5 }
    alerts_json { "MyText" }
  end
end
