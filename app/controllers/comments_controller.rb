class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @guide_profile = GuideProfile.find(params[:guide_profile_id])

    # Check if user has bookings with this guide
    unless current_user.has_booking_with_guide?(@guide_profile.user)
      respond_to do |format|
        format.html { redirect_to @guide_profile, alert: "You can only comment on guides you have booked tours with." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("comment_form",
                                                    partial: "comments/error_message",
                                                    locals: { message: "You can only comment on guides " \
                                                                       "you have booked tours with." })
        end
      end
      return
    end

    @comment = @guide_profile.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      respond_to do |format|
        format.html { redirect_to @guide_profile, notice: "Comment added successfully." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @guide_profile, alert: "Failed to add comment." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("comment_form",
                                                    partial: "comments/form",
                                                    locals: { guide_profile: @guide_profile,
                                                              comment: @comment })
        end
      end
    end
  end

  def toggle_like
    @comment = Comment.find(params[:id])
    authorize @comment, :toggle_like?

    @guide_profile = @comment.guide_profile
    like = @comment.likes.find_by(user: current_user)

    if like
      like.destroy
      @is_liked = false
    else
      @comment.likes.create!(user: current_user)
      @is_liked = true
    end

    # Reload to get updated counter cache
    @comment.reload

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def comment_params
    # Permit comment content
    params.expect(comment: [:content])
  end
end
