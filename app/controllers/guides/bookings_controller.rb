# frozen_string_literal: true

module Guides
  # Controller for guides to manage bookings for their tours
  class BookingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_guide!
    before_action :set_booking, only: %i[edit update cancel]
    before_action :authorize_booking, only: %i[edit update cancel]

    def index
      @bookings = policy_scope(Booking)
                  .joins(:tour)
                  .where(tours: { guide_id: current_user.id })
                  .includes(:tour, :user, booking_add_ons: :tour_add_on)
                  .order(created_at: :desc)

      # Filter by status
      @bookings = @bookings.where(status: params[:status]) if params[:status].present?

      # Filter by tour
      @bookings = @bookings.where(tour_id: params[:tour_id]) if params[:tour_id].present?

      # Search by user name or email
      if params[:q].present?
        search_query = "%#{params[:q]}%"
        @bookings = @bookings.where("users.name ILIKE ? OR users.email ILIKE ?", search_query, search_query)
      end

      @tours = current_user.tours.order(:title) # For filter dropdown
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@booking),
            partial: "guides/bookings/booking_edit_form",
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
                partial: "guides/bookings/booking",
                locals: { booking: @booking }
              ),
              turbo_stream.append(
                "notifications",
                partial: "shared/notification",
                locals: { message: "Booking updated successfully", type: "success" }
              )
            ]
          end
          format.html { redirect_to guides_bookings_path, notice: "Booking was successfully updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              dom_id(@booking),
              partial: "guides/bookings/booking_edit_form",
              locals: { booking: @booking }
            ), status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def cancel
      if @booking.update(status: "cancelled")
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(
                dom_id(@booking),
                partial: "guides/bookings/booking",
                locals: { booking: @booking }
              ),
              turbo_stream.append(
                "notifications",
                partial: "shared/notification",
                locals: { message: "Booking cancelled successfully", type: "info" }
              )
            ]
          end
          format.html { redirect_to guides_bookings_path, notice: "Booking was cancelled." }
        end
      else
        redirect_to guides_bookings_path, alert: "Could not cancel booking."
      end
    end

    private

    def set_booking
      @booking = Booking.joins(:tour)
                        .where(tours: { guide_id: current_user.id })
                        .includes(:tour, :user, booking_add_ons: :tour_add_on)
                        .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to guides_bookings_path, alert: "Booking not found or you don't have permission to access it."
    end

    def authorize_booking
      authorize @booking
    end

    def ensure_guide!
      redirect_to root_path, alert: "Access denied. Guides only." unless current_user&.guide?
    end

    def booking_params
      params.expect(booking: %i[status notes])
    end
  end
end
