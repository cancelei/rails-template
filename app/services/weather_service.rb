class WeatherService
  BASE_URL = "https://api.openweathermap.org/data/2.5".freeze
  API_KEY = ENV.fetch("OPENWEATHERMAP_API_KEY", nil)

  def self.fetch_forecast(latitude, longitude)
    return [] unless API_KEY

    response = HTTParty.get("#{BASE_URL}/onecall", query: {
      lat: latitude,
      lon: longitude,
      exclude: "current,minutely,hourly,alerts",
      units: "metric",
      appid: API_KEY
    })

    if response.success?
      response["daily"].first(8).map do |day|
        {
          forecast_date: Time.zone.at(day["dt"]).to_date,
          min_temp: day["temp"]["min"],
          max_temp: day["temp"]["max"],
          description: day["weather"].first["description"],
          icon: day["weather"].first["icon"],
          pop: day["pop"],
          wind_speed: day["wind_speed"]
        }
      end
    else
      []
    end
  end
end
