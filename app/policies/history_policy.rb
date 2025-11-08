class HistoryPolicy < ApplicationPolicy
  def show?
    user.present? && user.tourist?
  end
end
