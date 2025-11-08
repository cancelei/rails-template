# Renders the home page.
class HomeController < ApplicationController
  # @route GET / (root)
  def index
    # Popular tours - tours with high booking rate (likely to sell out soon)
    # Tours with less than 30% capacity remaining OR high booking activity
    @popular_tours = policy_scope(Tour)
                     .with_attached_cover_image
                     .includes(guide: :guide_profile)
                     .where(status: :scheduled)
                     .where("starts_at > ?", Time.current)
                     .where(starts_at: ...7.days.from_now) # Next 7 days
                     .select { |t| t.available_spots.to_f / t.capacity < 0.3 || t.bookings_count > 5 }
                     .sort_by { |t| t.available_spots.to_f / t.capacity }
                     .first(6)

    # All upcoming tours available for booking
    @tours = policy_scope(Tour)
             .with_attached_cover_image
             .includes(guide: :guide_profile)
             .where(status: :scheduled)
             .where("starts_at > ?", Time.current)
             .order(:starts_at)
             .limit(12)

    return unless user_signed_in?

    # User's confirmed bookings for upcoming tours
    @booked_tours = current_user.bookings
                                .confirmed
                                .joins(:tour)
                                .includes(tour: [:guide, { guide: :guide_profile }])
                                .where("tours.starts_at > ?", Time.current)
                                .order("tours.starts_at")

    # Past tours (both available tours and user's bookings)
    @past_tours = policy_scope(Tour)
                  .includes(guide: :guide_profile)
                  .where(ends_at: ...Time.current)
                  .order(ends_at: :desc)
                  .limit(10)
  end
end
