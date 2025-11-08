module Admin
  class BookingsController < Admin::BaseController
    include ActionView::RecordIdentifier

    before_action :set_booking, only: %i[show edit update destroy]

    def index
      @bookings = Booking.includes(:tour, :user, booking_add_ons: :tour_add_on).order(created_at: :desc)
      @bookings = @bookings.where(status: params[:status]) if params[:status].present?
      @bookings = @bookings.page(params[:page]).per(25)
    end

    def show
      respond_to do |format|
        format.turbo_stream do
          # For canceling inline edits, return the display view
          render turbo_stream: turbo_stream.replace(
            dom_id(@booking),
            partial: "admin/bookings/booking",
            locals: { booking: @booking }
          )
        end
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@booking),
            partial: "admin/bookings/booking_edit_form",
            locals: { booking: @booking }
          )
        end
        format.html
      end
    end

    def update
      if @booking.update(booking_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                dom_id(@booking),
                partial: "admin/bookings/booking",
                locals: { booking: @booking }
              ),
              turbo_stream.append(
                "notifications",
                partial: "admin/shared/notification",
                locals: { message: "Booking updated successfully", type: "success" }
              )
            ]
          end
          format.html { redirect_to admin_bookings_path, notice: "Booking was successfully updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              dom_id(@booking),
              partial: "admin/bookings/booking_edit_form",
              locals: { booking: @booking }
            ), status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @booking.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(dom_id(@booking)),
            turbo_stream.append("notifications", partial: "admin/shared/notification",
                                                 locals: { message: "Booking deleted", type: "info" })
          ]
        end
        format.html { redirect_to admin_bookings_path, notice: "Booking was successfully deleted." }
      end
    end

    private

    def set_booking
      @booking = Booking.includes(:tour, :user, booking_add_ons: :tour_add_on).find(params[:id])
    end

    def booking_params
      params.expect(booking: %i[status notes])
    end
  end
end
