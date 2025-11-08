class ToursController < ApplicationController
  include ActionView::RecordIdentifier
  include InlineEditable

  before_action :authenticate_user!, only: %i[new create edit update]
  before_action :set_tour, only: %i[edit update]
  before_action :authorize_tour, only: %i[edit update]
  skip_after_action :verify_authorized, only: %i[show index]

  def index
    @tours = policy_scope(Tour)
             .includes(
               guide: :guide_profile,
               cover_image_attachment: :blob
             )

    # Search by query (title, location, or guide name)
    if params[:q].present?
      search_query = "%#{params[:q]}%"
      @tours = @tours.left_joins(guide: :guide_profile)
                     .where("tours.title ILIKE ? OR tours.location_name ILIKE ? OR users.name ILIKE ?",
                            search_query, search_query, search_query)
    end

    # Filter by location
    @tours = @tours.where("tours.location_name ILIKE ?", "%#{params[:location]}%") if params[:location].present?

    # Filter by max price
    if params[:max_price].present?
      max_price_cents = params[:max_price].to_i * 100
      @tours = @tours.where(tours: { price_cents: ..max_price_cents })
    end

    # Filter by availability
    @tours = @tours.where("tours.capacity - tours.bookings_count > 0") if params[:availability] == "available"

    @tours = @tours.order(starts_at: :asc)
  end

  def show
    # Load tour with all associations needed for show view
    @tour = Tour
            .includes(
              :weather_snapshots,
              guide: :guide_profile,
              tour_add_ons: [],
              cover_image_attachment: :blob,
              images_attachments: :blob
            )
            .find(params[:id])
    authorize @tour
    @weather_snapshots = @tour.weather_snapshots.order(:forecast_date)
  end

  def new
    @tour = current_user.tours.build
    authorize @tour
  end

  def edit
    # Check if this is a turbo frame request from the show page
    return unless turbo_frame_request? && turbo_frame_request_id == dom_id(@tour)

    # Render inline edit form for turbo frame
    render partial: "tour_details_edit_form", locals: { tour: @tour }

    # Render full page edit form
    # This is the default behavior - renders edit.html.erb
  end

  def create
    @tour = current_user.tours.build(tour_params)
    authorize @tour

    if @tour.save
      redirect_to @tour, notice: "Tour was successfully created."
    else
      render :new
    end
  end

  def update
    if @tour.update(tour_params)
      # Check if this is a turbo frame request
      if turbo_frame_request? && turbo_frame_request_id == dom_id(@tour)
        # Reload to get fresh data
        @tour.reload

        # Use turbo stream to replace content AND show notification
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@tour),
            partial: "tour_details",
            locals: { tour: @tour }
          ),
          turbo_stream.prepend(
            "notifications",
            partial: "shared/notification",
            locals: { message: "Tour updated successfully", type: "success" }
          )
        ]
      else
        # Regular redirect for full page edit
        redirect_to @tour, notice: "Tour was successfully updated."
      end
    elsif turbo_frame_request? && turbo_frame_request_id == dom_id(@tour)
      # Re-render edit form with errors
      render turbo_stream: turbo_stream.replace(
        dom_id(@tour),
        partial: "tour_details_edit_form",
        locals: { tour: @tour }
      ), status: :unprocessable_entity
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_tour
    # Simple find for edit/update actions - no associations needed
    @tour = Tour.find(params[:id])
  end

  def authorize_tour
    authorize @tour
  end

  def tour_params
    params.expect(tour: [:title, :description, :capacity, :price_cents, :currency, :location_name, :latitude,
                         :longitude, :starts_at, :ends_at, :tour_type, :booking_deadline_hours, :cover_image,
                         { images: [] }])
  end
end
