class TourMailer < ApplicationMailer
  # Notify guide when their tour has ended
  def tour_completed_guide(tour)
    @tour = tour
    @guide = tour.guide
    @confirmed_bookings_count = tour.bookings.confirmed.count
    @total_participants = tour.bookings.confirmed.sum(:spots)

    mail(
      to: @guide.email,
      subject: "Tour Completed: #{@tour.title}"
    )
  end

  # Notify tourist when tour has ended and invite them to leave a review
  def tour_completed_tourist(booking)
    @booking = booking
    @tour = booking.tour
    @guide = @tour.guide
    @can_review = booking.review.blank?

    mail(
      to: booking.booked_email,
      subject: "Thanks for Joining: #{@tour.title}"
    )
  end
end
