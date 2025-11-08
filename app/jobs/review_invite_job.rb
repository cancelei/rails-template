class ReviewInviteJob < ApplicationJob
  queue_as :default

  # Send tour completion emails and review invitations for a specific tour
  def perform(tour_id)
    tour = Tour.find_by(id: tour_id)
    return unless tour&.done?

    # Send completion email to guide
    TourMailer.tour_completed_guide(tour).deliver_later

    # Send completion email with review invitation to each tourist
    tour.bookings.confirmed.includes(:tour, :user).find_each do |booking|
      TourMailer.tour_completed_tourist(booking).deliver_later
    end
  end
end
