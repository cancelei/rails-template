module Guides
  class ProfileController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_guide!
    before_action :set_guide_profile

    def update
      if @guide_profile.update(guide_profile_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                "guide_profile",
                partial: "guides/dashboard/profile",
                locals: { guide_profile: @guide_profile }
              ),
              turbo_stream.append(
                "notifications",
                partial: "shared/notification",
                locals: { message: "Profile updated successfully", type: "success" }
              )
            ]
          end
          format.html { redirect_to guide_dashboard_path, notice: "Profile updated successfully" }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "guide_profile_form",
              partial: "guides/dashboard/profile_form",
              locals: { guide_profile: @guide_profile }
            ), status: :unprocessable_entity
          end
          format.html { redirect_to guide_dashboard_path, alert: "Failed to update profile" }
        end
      end
    end

    private

    def set_guide_profile
      @guide_profile = current_user.guide_profile || current_user.create_guide_profile
    end

    def ensure_guide!
      return if current_user.guide?

      redirect_to root_path, alert: "Only tour guides can access this page"
    end

    def guide_profile_params
      params.expect(guide_profile: %i[bio languages years_of_experience certifications])
    end
  end
end
