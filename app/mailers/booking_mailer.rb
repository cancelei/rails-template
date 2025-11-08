class BookingMailer < ApplicationMailer
  def confirmation(booking)
    @booking = booking
    @tour = booking.tour
    mail(to: booking.booked_email, subject: "Booking Confirmation")
  end

  def cancellation(booking)
    @booking = booking
    @tour = booking.tour
    mail(to: booking.booked_email, subject: "Booking Cancellation")
  end

  def reminder(booking, days_until)
    @booking = booking
    @tour = booking.tour
    @days_until = days_until
    mail(to: booking.booked_email, subject: "Reminder: Tour in #{days_until} days")
  end
end
