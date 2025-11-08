class BookingsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :set_tour, only: [:create]
  before_action :set_booking, only: %i[manage cancel review]

  def create
    @booking = @tour.bookings.build(booking_params)
    @booking.user = current_user
    authorize @booking

    if @booking.save
      # Create booking add-ons if selected
      if params[:add_on_ids].present?
        params[:add_on_ids].compact_blank.each do |add_on_id|
          tour_add_on = @tour.tour_add_ons.find_by(id: add_on_id)
          next unless tour_add_on&.active?

          @booking.booking_add_ons.create!(
            tour_add_on:,
            quantity: 1,
            price_cents_at_booking: tour_add_on.price_cents
          )
        end
      end

      # Reload booking with associations for email
      @booking = Booking.includes(:tour, booking_add_ons: :tour_add_on).find(@booking.id)

      # Send confirmation email
      BookingMailer.confirmation(@booking).deliver_later
      redirect_to manage_booking_path(@booking, email: current_user.email), notice: "Booking was successful."
    else
      redirect_to @tour, alert: @booking.errors.full_messages.join(", ")
    end
  end

  def manage
    authorize @booking
    # Magic link page for managing booking
  end

  def cancel
    authorize @booking
    if @booking.cancel!
      # Send cancellation email
      BookingMailer.cancellation(@booking).deliver_later
      redirect_path = params[:email].present? ? manage_booking_path(@booking, email: @booking.booked_email) : root_path
      redirect_to redirect_path, notice: "Booking was cancelled."
    else
      redirect_path = params[:email].present? ? manage_booking_path(@booking, email: @booking.booked_email) : root_path
      redirect_to redirect_path, alert: "Could not cancel booking."
    end
  end

  def review
    authorize @booking
    @review = @booking.build_review(review_params)
    @review.user = @booking.user

    redirect_path = params[:email].present? ? manage_booking_path(@booking, email: @booking.booked_email) : root_path
    if @review.save
      redirect_to redirect_path, notice: "Review was submitted."
    else
      redirect_to redirect_path, alert: @review.errors.full_messages.join(", ")
    end
  end

  private

  def set_tour
    @tour = Tour.find(params[:tour_id])
  end

  def set_booking
    base_query = Booking.includes(:tour, booking_add_ons: :tour_add_on)

    if params[:email].present?
      # Magic link access (for guest bookings)
      @booking = base_query.find_by(id: params[:id], booked_email: params[:email])
    elsif user_signed_in?
      # Logged-in user access
      @booking = current_user.bookings.merge(base_query).find_by(id: params[:id])
    end
  end

  def booking_params
    params.expect(booking: [:spots])
  end

  def review_params
    params.expect(review: %i[rating comment])
  end
end
