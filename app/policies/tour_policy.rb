# TourPolicy
# Defines authorization rules for Tour resources
#
# Permission hierarchy:
#   - Admin: Full access to all tours
#   - Guide: Can manage their own tours
#   - Tourist/Guest: Read-only access
class TourPolicy < ApplicationPolicy
  # Public show access for all users
  def show?
    true
  end

  # Only admins and tour owners (guides) can create tours
  def create?
    return false unless user

    admin? || guide?
  end

  # Only admins and tour owners can update tours
  def update?
    return false unless user

    admin? || record_guide?
  end

  # Editing follows update permissions
  def edit?
    update?
  end

  # Only admins and tour owners can delete tours
  def destroy?
    return false unless user

    admin? || record_guide?
  end

  # Only admins and tour owners can cancel tours
  def cancel?
    return false unless user

    admin? || record_guide?
  end

  # Inline editing is available for admins and tour owners
  # This allows admins to edit any tour directly in the public view
  def inline_edit?
    return false unless user

    admin? || record_guide?
  end

  # Admins can manage all aspects of any tour
  def manage?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    # Scope resolver for tour listings
    # - Admins see all tours
    # - Guides see only their tours
    # - Others see all public tours
    def resolve
      if admin?
        scope.all
      elsif guide?
        scope.where(guide: user)
      else
        scope.all # Public access to all tours
      end
    end
  end
end
