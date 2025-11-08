module Admin
  class GuideProfilesController < Admin::BaseController
    before_action :set_guide_profile, only: %i[show edit update]

    def index
      @guide_profiles = GuideProfile.includes(:user).order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @tours = @guide_profile.user.tours.includes(:bookings, :reviews, :weather_snapshots).order(starts_at: :desc)
      @comments = @guide_profile.comments.includes(:user).order(created_at: :desc)
    end

    def edit
    end

    def update
      if @guide_profile.update(guide_profile_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                dom_id(@guide_profile, :profile),
                partial: "admin/guide_profiles/profile_section",
                locals: { guide_profile: @guide_profile }
              ),
              turbo_stream.append(
                "notifications",
                partial: "shared/notification",
                locals: { message: "Profile updated successfully", type: "success" }
              )
            ]
          end
          format.html { redirect_to admin_guide_profile_path(@guide_profile), notice: "Guide profile updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              dom_id(@guide_profile, :profile),
              partial: "admin/guide_profiles/edit",
              locals: { guide_profile: @guide_profile }
            ), status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_guide_profile
      @guide_profile = GuideProfile.find(params[:id])
    end

    def guide_profile_params
      params.expect(guide_profile: %i[bio certifications languages years_of_experience])
    end
  end
end
