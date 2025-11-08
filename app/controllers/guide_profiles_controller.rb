class GuideProfilesController < ApplicationController
  include InlineEditable

  before_action :set_guide_profile, only: %i[edit update]
  before_action :authorize_guide_profile, only: %i[edit update]
  skip_after_action :verify_authorized, only: [:show]

  def show
    @guide_profile = GuideProfile.find(params[:id])
    @tours = @guide_profile.user.tours.includes(:weather_snapshots)
    @last_tours = @guide_profile.user.tours.where(status: :done).order(created_at: :desc).limit(5)
    @upcoming_tours = @guide_profile.user.tours.where(status: :scheduled).where("starts_at > ?",
                                                                                Time.current).order(:starts_at)
  end

  def edit
    # Render inline edit form
    render_inline_edit_form(@guide_profile, partial: "guide_profiles/profile_edit_form")
  end

  def update
    if @guide_profile.update(guide_profile_params)
      render_inline_update_success(
        @guide_profile,
        display_partial: "guide_profiles/profile_display",
        message: "Guide profile updated successfully"
      )
    else
      render_inline_update_failure(@guide_profile, partial: "guide_profiles/profile_edit_form")
    end
  end

  private

  def set_guide_profile
    @guide_profile = GuideProfile.find(params[:id])
  end

  def authorize_guide_profile
    authorize @guide_profile
  end

  def guide_profile_params
    params.expect(guide_profile: %i[bio languages rating_cached])
  end
end
