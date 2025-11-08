module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    layout "admin"

    # Admin controllers handle their own authorization
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    # Skip the ApplicationController rescue_from for Pundit errors
    # so that admin authorization errors are raised directly
    rescue_from Pundit::NotAuthorizedError do |exception|
      raise exception
    end

    private

    def require_admin
      return if current_user.admin?

      raise Pundit::NotAuthorizedError, "Access denied. Admin privileges required."
    end
  end
end
