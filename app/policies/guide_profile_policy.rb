# GuideProfilePolicy
# Defines authorization rules for GuideProfile resources
#
# Permission hierarchy:
#   - Admin: Full access to all guide profiles
#   - Guide: Can manage their own profile
#   - Tourist/Guest: Read-only access
class GuideProfilePolicy < ApplicationPolicy
  # Public show access for all users
  def show?
    true
  end

  # Only admins and profile owners can update profiles
  def update?
    return false unless user

    admin? || owner?
  end

  # Editing follows update permissions
  def edit?
    update?
  end

  # Only admins can delete guide profiles
  # Guides cannot delete their own profiles (soft delete should be used via user account)
  def destroy?
    return false unless user

    admin?
  end

  # Inline editing is available for admins and profile owners
  # This allows admins to edit any guide profile directly in the public view
  def inline_edit?
    return false unless user

    admin? || owner?
  end

  # Admins can manage all aspects of any guide profile
  def manage?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    # Scope resolver for guide profile listings
    # - Admins see all profiles
    # - Guides see only their own profile
    # - Others see all public profiles
    def resolve
      if admin?
        scope.all
      elsif guide?
        scope.where(user:)
      else
        scope.all # Public access to all guide profiles
      end
    end
  end
end
