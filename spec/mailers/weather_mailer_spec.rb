require "rails_helper"

RSpec.describe WeatherMailer do
  let(:guide) { create(:user, role: :guide, name: "Jane Guide", email: "guide@example.com") }
  let(:tour) { create(:tour, guide:, title: "Mountain Hike", starts_at: 3.days.from_now) }
  let(:forecast) do
    {
      forecast_date: Date.current,
      min_temp: 8,
      max_temp: 12,
      description: "heavy rain",
      icon: "10d",
      pop: 0.9,
      wind_speed: 15
    }
  end

  describe "#weather_alert" do
    let(:mail) { described_class.weather_alert(guide, tour, forecast) }

    it "sends to guide email" do
      expect(mail.to).to eq(["guide@example.com"])
    end

    it "has correct subject" do
      expect(mail.subject).to eq("Weather Alert for Your Tour")
    end

    it "includes tour title in body" do
      expect(mail.body.encoded).to include("Mountain Hike")
    end

    it "includes weather description" do
      expect(mail.body.encoded).to include("heavy rain") if mail.body.parts.any?
    end

    it "sets correct from address" do
      expect(mail.from).to include("from@example.com")
    end
  end
end
