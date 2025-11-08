module Admin
  class ReviewsController < Admin::BaseController
    before_action :set_review, only: %i[show destroy]

    def index
      @reviews = Review.includes(:user, :guide_profile).order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
    end

    def destroy
      @review.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@review)) }
        format.html { redirect_to admin_reviews_path, notice: "Review deleted." }
      end
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end
  end
end
