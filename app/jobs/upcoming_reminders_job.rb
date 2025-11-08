class UpcomingRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # T-72h reminders
    bookings_72h = Booking.includes(:tour, booking_add_ons: :tour_add_on)
                          .joins(:tour)
                          .where(tours: { status: :scheduled })
                          .where("tours.starts_at BETWEEN ? AND ?", 72.hours.from_now, 73.hours.from_now)
    bookings_72h.each do |booking|
      BookingMailer.reminder(booking, 3).deliver_later
    end

    # T-24h reminders
    bookings_24h = Booking.includes(:tour, booking_add_ons: :tour_add_on)
                          .joins(:tour)
                          .where(tours: { status: :scheduled })
                          .where("tours.starts_at BETWEEN ? AND ?", 24.hours.from_now, 25.hours.from_now)
    bookings_24h.each do |booking|
      BookingMailer.reminder(booking, 1).deliver_later
    end
  end
end
