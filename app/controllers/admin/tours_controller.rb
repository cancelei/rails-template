module Admin
  class ToursController < Admin::BaseController
    include ActionView::RecordIdentifier

    before_action :set_tour, only: %i[show edit update destroy]

    def index
      @tours = Tour.includes(:guide).order(created_at: :desc)
      @tours = @tours.where(status: params[:status]) if params[:status].present?
      @tours = @tours.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      @tours = @tours.page(params[:page]).per(25)
    end

    def show
      respond_to do |format|
        format.turbo_stream do
          # For canceling inline edits, return the display view
          render turbo_stream: turbo_stream.replace(
            dom_id(@tour),
            partial: "admin/tours/tour",
            locals: { tour: @tour }
          )
        end
        format.html
      end
    end

    def new
      @tour = Tour.new
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          # Check context to determine which edit form to render
          if request.referer&.include?("guide_profiles")
            render turbo_stream: turbo_stream.replace(
              dom_id(@tour),
              partial: "admin/guide_profiles/tour_edit_form",
              locals: { tour: @tour }
            )
          else
            # Default to tours index inline edit form
            render turbo_stream: turbo_stream.replace(
              dom_id(@tour),
              partial: "admin/tours/tour_edit_form",
              locals: { tour: @tour }
            )
          end
        end
        format.html
      end
    end

    def create
      @tour = Tour.new(tour_params)

      if @tour.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("tours_table_body", partial: "admin/tours/tour", locals: { tour: @tour }),
              turbo_stream.append("notifications", partial: "admin/shared/notification",
                                                   locals: { message: "Tour created successfully", type: "success" }),
              turbo_stream.update("modal", "")
            ]
          end
          format.html { redirect_to admin_tours_path, notice: "Tour was successfully created." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @tour.update(tour_params)
        respond_to do |format|
          format.turbo_stream do
            # Check context to determine which partial to render
            if request.referer&.include?("guide_profiles")
              # Guide profile page context
              render turbo_stream: [
                turbo_stream.replace(
                  dom_id(@tour),
                  partial: "admin/guide_profiles/tour_row",
                  locals: { tour: @tour }
                ),
                turbo_stream.append(
                  "notifications",
                  partial: "shared/notification",
                  locals: { message: "Tour updated successfully", type: "success" }
                )
              ]
            else
              # Tours index page context
              render turbo_stream: [
                turbo_stream.replace(
                  dom_id(@tour),
                  partial: "admin/tours/tour",
                  locals: { tour: @tour }
                ),
                turbo_stream.append(
                  "notifications",
                  partial: "admin/shared/notification",
                  locals: { message: "Tour updated successfully", type: "success" }
                )
              ]
            end
          end
          format.html { redirect_to admin_tours_path, notice: "Tour was successfully updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            # Re-render edit form with errors
            if request.referer&.include?("guide_profiles")
              render turbo_stream: turbo_stream.replace(
                dom_id(@tour),
                partial: "admin/guide_profiles/tour_edit_form",
                locals: { tour: @tour }
              ), status: :unprocessable_entity
            else
              render turbo_stream: turbo_stream.replace(
                dom_id(@tour),
                partial: "admin/tours/tour_edit_form",
                locals: { tour: @tour }
              ), status: :unprocessable_entity
            end
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @tour.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(dom_id(@tour)),
            turbo_stream.append("notifications", partial: "admin/shared/notification",
                                                 locals: { message: "Tour deleted", type: "info" })
          ]
        end
        format.html { redirect_to admin_tours_path, notice: "Tour was successfully deleted." }
      end
    end

    private

    def set_tour
      @tour = Tour.find(params[:id])
    end

    def tour_params
      params.expect(tour: [:title, :description, :guide_id, :status, :capacity,
                           :price_cents, :currency, :location_name, :latitude, :longitude,
                           :starts_at, :ends_at, :tour_type, :booking_deadline_hours, :cover_image,
                           { images: [] }])
    end
  end
end
