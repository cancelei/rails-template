class TourAddOnPolicy < ApplicationPolicy
  def index?
    return false if user.nil?

    user.admin? || (user.guide? && record.tour.guide == user)
  end

  def show?
    # Active add-ons are publicly viewable on tour pages
    record.active?
  end

  def create?
    return false if user.nil?

    user.admin? || (user.guide? && record.tour.guide == user)
  end

  def new?
    create?
  end

  def update?
    return false if user.nil?

    user.admin? || (user.guide? && record.tour.guide == user)
  end

  def edit?
    update?
  end

  def destroy?
    return false if user.nil?

    user.admin? || (user.guide? && record.tour.guide == user)
  end

  def reorder?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.guide?
        scope.joins(:tour).where(tours: { guide: user })
      else
        scope.active # Tourists/unauthenticated can only see active add-ons
      end
    end
  end
end
