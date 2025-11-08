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
require "rails_helper"

RSpec.describe WeatherSnapshot do
  let(:tour) { create(:tour) }
  let(:weather_snapshot) { build(:weather_snapshot, tour:, forecast_date: Time.zone.today) }

  describe "associations" do
    it { is_expected.to belong_to(:tour) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:forecast_date) }
    it { is_expected.to validate_numericality_of(:min_temp) }
    it { is_expected.to validate_numericality_of(:max_temp) }
    it { is_expected.to validate_numericality_of(:pop) }
    it { is_expected.to validate_numericality_of(:wind_speed) }

    it "allows nil for numeric fields" do
      weather_snapshot.min_temp = nil
      weather_snapshot.max_temp = nil
      weather_snapshot.pop = nil
      weather_snapshot.wind_speed = nil
      expect(weather_snapshot).to be_valid
    end
  end

  describe "attributes" do
    it "stores forecast_date" do
      weather_snapshot.save
      expect(weather_snapshot.reload.forecast_date).to eq(Time.zone.today)
    end

    it "stores temperature data" do
      weather_snapshot.min_temp = 15.5
      weather_snapshot.max_temp = 25.3
      weather_snapshot.save
      expect(weather_snapshot.reload.min_temp).to eq(15.5)
      expect(weather_snapshot.reload.max_temp).to eq(25.3)
    end

    it "stores weather description and icon" do
      weather_snapshot.description = "Partly cloudy"
      weather_snapshot.icon = "partly-cloudy"
      weather_snapshot.save
      expect(weather_snapshot.reload.description).to eq("Partly cloudy")
      expect(weather_snapshot.reload.icon).to eq("partly-cloudy")
    end

    it "stores alerts as JSON" do
      alerts = '{"warning": "Heavy rain expected"}'
      weather_snapshot.alerts_json = alerts
      weather_snapshot.save
      expect(weather_snapshot.reload.alerts_json).to eq(alerts)
    end
  end
end
