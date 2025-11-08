# frozen_string_literal: true

# ApplicationPolicy
# Base policy class for all Pundit policies
#
# Provides common permission checking methods and role-based helpers
# All specific policies should inherit from this class
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    true
  end

  def edit?
    update?
  end

  def destroy?
    true
  end

  # Permission helper methods

  # Check if user is an admin
  # Admins have full access to all resources
  #
  # @return [Boolean] true if user has admin role
  def admin?
    user&.admin?
  end

  # Check if user is a guide
  #
  # @return [Boolean] true if user has guide role
  def guide?
    user&.guide?
  end

  # Check if user is a tourist
  #
  # @return [Boolean] true if user has tourist role
  def tourist?
    user&.tourist?
  end

  # Check if user owns the record
  # Useful for policies where ownership determines permissions
  #
  # @return [Boolean] true if user owns the record
  def owner?
    return false unless user && record.respond_to?(:user_id)

    record.user_id == user.id
  end

  # Check if user is the guide for this record
  # Useful for tour-related records
  #
  # @return [Boolean] true if user is the guide for this record
  def record_guide?
    return false unless user && record.respond_to?(:guide_id)

    record.guide_id == user.id
  end

  # Check if user can manage (full CRUD) this record
  # By default, admins can manage all records
  #
  # @return [Boolean] true if user can manage the record
  def manage?
    admin?
  end

  # Check if user has any permission to edit
  # Override in specific policies to customize
  #
  # @return [Boolean] true if user can edit
  def can_edit?
    update?
  end

  # Check if user can inline edit this record
  # Inline editing is typically available for admins and owners
  #
  # @return [Boolean] true if user can inline edit
  def inline_edit?
    can_edit?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    # Helper method for admin check in scopes
    def admin?
      user&.admin?
    end

    # Helper method for guide check in scopes
    def guide?
      user&.guide?
    end

    # Helper method for tourist check in scopes
    def tourist?
      user&.tourist?
    end

    private

    attr_reader :user, :scope
  end
end
