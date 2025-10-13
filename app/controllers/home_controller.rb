# Renders the home page.
class HomeController < ApplicationController
  def index
    # tell pundit that we are ok with not having authorization on this endpoint
    skip_policy_scope
  end
end
