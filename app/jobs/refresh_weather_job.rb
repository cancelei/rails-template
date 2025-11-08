class RefreshWeatherJob < ApplicationJob
  queue_as :default

  def perform
    upcoming_tours.each { |tour| process_tour(tour) }
  end

  private

  def upcoming_tours
    Tour.where(status: %i[scheduled ongoing]).where(starts_at: ..8.days.from_now)
  end

  def process_tour(tour)
    return unless tour.latitude && tour.longitude

    forecasts = fetch_forecasts(tour)
    return if forecasts.blank?

    forecasts.each { |forecast| process_forecast(tour, forecast) }
  rescue StandardError => e
    Rails.logger.error("Failed to fetch weather for tour #{tour.id}: #{e.message}")
  end

  def fetch_forecasts(tour)
    WeatherService.fetch_forecast(tour.latitude, tour.longitude)
  end

  def process_forecast(tour, forecast)
    snapshot = WeatherSnapshot.find_or_initialize_by(tour:, forecast_date: forecast[:forecast_date])

    notify_if_weather_changed(snapshot, tour, forecast)
    update_snapshot(snapshot, forecast)
  end

  def notify_if_weather_changed(snapshot, tour, forecast)
    return unless snapshot.persisted? && weather_changed_significantly?(snapshot, forecast)

    notify_guide_of_weather_change(tour, forecast)
  end

  def update_snapshot(snapshot, forecast)
    snapshot.update!(
      min_temp: forecast[:min_temp],
      max_temp: forecast[:max_temp],
      description: forecast[:description],
      icon: forecast[:icon],
      pop: forecast[:pop],
      wind_speed: forecast[:wind_speed]
    )
  end

  def weather_changed_significantly?(existing, new_forecast)
    # If existing had no rain (pop < 0.3) but new has rain (pop > 0.7)
    existing.pop < 0.3 && new_forecast[:pop] > 0.7
  end

  def notify_guide_of_weather_change(tour, forecast)
    # Send email to guide about weather change
    WeatherMailer.weather_alert(tour.guide, tour, forecast).deliver_later
  end
end
