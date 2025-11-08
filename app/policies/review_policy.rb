class ReviewPolicy < ApplicationPolicy
  def create?
    user.admin? || (user.tourist? && record.user == user && record.tour.done?)
  end

  def update?
    user.admin? || (user.tourist? && record.user == user)
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || (user.tourist? && record.user == user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user:)
      end
    end
  end
end
