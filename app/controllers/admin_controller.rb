class AdminController < Admin::BaseController
  def metrics
    @guide_count = User.where(role: :guide).count
    @tourist_count = User.where(role: :tourist).count
    @tour_count = Tour.count
    @upcoming_tour_count = Tour.where(status: :scheduled).where("starts_at > ?", Time.current).count
    @booking_count_7_days = Booking.where("created_at > ?", 7.days.ago).count
    @booking_count_30_days = Booking.where("created_at > ?", 30.days.ago).count
    @recent_bookings = Booking.includes(:tour, :user).order(created_at: :desc).limit(10)
  end
end
