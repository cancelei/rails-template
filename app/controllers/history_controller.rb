class HistoryController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :history

    @past_bookings = current_user.bookings
                                 .includes(:review, tour: { guide: :guide_profile })
                                 .joins(:tour)
                                 .where(tours: { starts_at: ...Time.current })
                                 .order("tours.starts_at DESC")

    @guide_stats = calculate_guide_stats
  end

  private

  def calculate_guide_stats
    # Group past bookings by guide and calculate tour counts
    current_user.bookings
                .joins(:tour)
                .where(tours: { starts_at: ...Time.current })
                .where(status: :confirmed)
                .group("tours.guide_id")
                .select("tours.guide_id, COUNT(DISTINCT tours.id) as tour_count")
                .map do |stat|
      guide = User.find(stat.guide_id)
      {
        guide:,
        guide_profile: guide.guide_profile,
        tour_count: stat.tour_count,
        total_spots: current_user.bookings
                                 .joins(:tour)
                                 .where(tours: { guide_id: stat.guide_id })
                                 .where(tours: { starts_at: ...Time.current })
                                 .where(status: :confirmed)
                                 .sum(:spots),
        comment_count: current_user.comments
                                   .where(guide_profile_id: guide.guide_profile&.id)
                                   .count,
        like_count: current_user.likes
                                .joins(:comment)
                                .where(comments: { guide_profile_id: guide.guide_profile&.id })
                                .count
      }
    end.sort_by { |stat| -stat[:tour_count] }
  end
end
