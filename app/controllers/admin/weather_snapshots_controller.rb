module Admin
  class WeatherSnapshotsController < Admin::BaseController
    def index
      @weather_snapshots = WeatherSnapshot.includes(:tour).order(created_at: :desc).page(params[:page]).per(25)
    end
  end
end
