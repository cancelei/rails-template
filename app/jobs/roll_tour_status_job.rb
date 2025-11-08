class RollTourStatusJob < ApplicationJob
  queue_as :default

  def perform
    # scheduled -> ongoing (inclusive of current time)
    Tour.where(status: :scheduled).where(starts_at: ..Time.current).update_all(status: :ongoing)

    # ongoing -> done (exclusive - must be in the past)
    # Track which tours are being marked as done so we can send completion emails
    completed_tour_ids = Tour.where(status: :ongoing)
                             .where(ends_at: ...Time.current)
                             .pluck(:id)

    Tour.where(id: completed_tour_ids).update_all(status: :done)

    # Queue review invitation emails for each completed tour
    completed_tour_ids.each do |tour_id|
      ReviewInviteJob.perform_later(tour_id)
    end
  end
end
