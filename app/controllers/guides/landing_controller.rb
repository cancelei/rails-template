module Guides
  class LandingController < ApplicationController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def index
      # Show landing page for potential guides
      @total_guides = User.where(role: :guide).count
      @total_tours = Tour.count
      @total_bookings = Booking.count
      @average_rating = GuideProfile.where.not(rating_cached: nil).average(:rating_cached)&.round(1) || 4.8
    end
  end
end
