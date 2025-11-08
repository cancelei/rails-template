class WeatherMailer < ApplicationMailer
  def weather_alert(guide, tour, forecast)
    @guide = guide
    @tour = tour
    @forecast = forecast
    mail(to: guide.email, subject: "Weather Alert for Your Tour")
  end
end
