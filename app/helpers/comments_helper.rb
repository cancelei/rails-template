module CommentsHelper
  # Get booking stats for a user with a guide (with caching for efficiency)
  def booking_stats_for_comment(user, guide_user)
    @booking_stats_cache ||= {}
    @booking_stats_cache[user.id] ||= user.booking_stats_with_guide(guide_user)
  end
end
