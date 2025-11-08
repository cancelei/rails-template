class CommentPolicy < ApplicationPolicy
  def create?
    # Users can only create comments on guides they have booked with
    user.present? && user.has_booking_with_guide?(record.guide_profile.user)
  end

  def toggle_like?
    # Any authenticated user can like any comment
    user.present?
  end
end
