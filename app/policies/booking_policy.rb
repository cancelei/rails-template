# BookingPolicy
# Defines authorization rules for Booking resources
#
# Permission hierarchy:
#   - Admin: Full access to all bookings
#   - Tourist: Can manage their own bookings
#   - Guide: Can view and manage bookings for their tours
#   - Guest: No access (must be authenticated)
class BookingPolicy < ApplicationPolicy
  # Only authenticated users can view bookings
  def show?
    return false unless user

    admin? || owner? || tour_guide?
  end

  # User must be logged in to create a booking
  def create?
    user.present?
  end

  # Only admins and booking owners can update bookings
  def update?
    return false unless user

    admin? || owner?
  end

  # Editing follows update permissions
  def edit?
    update?
  end

  # Only admins and booking owners can delete bookings
  def destroy?
    return false unless user

    admin? || owner?
  end

  # Admins, booking owners, and tour guides can cancel bookings
  def cancel?
    return false unless user

    admin? || owner? || tour_guide?
  end

  # Inline editing is available for admins and booking owners
  # This allows admins to edit any booking directly in any view
  def inline_edit?
    return false unless user

    admin? || owner?
  end

  # Magic link access for managing bookings via email
  # Anyone with the email can manage via magic link
  def manage?
    true
  end

  # Magic link access for reviewing after tour completion
  # Anyone with the email can review via magic link
  def review?
    true
  end

  private

  # Check if the current user is the tour guide for this booking
  def tour_guide?
    return false unless guide?

    record.tour.guide == user
  end

  class Scope < ApplicationPolicy::Scope
    # Scope resolver for booking listings
    # - Admins see all bookings
    # - Guides see bookings for their tours
    # - Tourists see their own bookings
    def resolve
      if admin?
        scope.all
      elsif guide?
        scope.joins(:tour).where(tours: { guide: user })
      elsif tourist?
        scope.where(user:)
      else
        scope.none
      end
    end
  end
end
