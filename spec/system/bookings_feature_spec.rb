require "rails_helper"

RSpec.describe "Bookings" do
  let(:password) { "passwordpassword" }
  let(:guide) { FactoryBot.create(:user, :guide, password:) }
  let(:tourist) { FactoryBot.create(:user, :tourist, password:) }
  let(:tour) { FactoryBot.create(:tour, guide:) }
  let(:booking) { FactoryBot.create(:booking, tour:, user: tourist) }

  describe "Creating a booking" do
    before do
      sign_in_user(tourist, password:)
      visit tour_path(tour)
    end

    it "allows a tourist to book a tour" do
      click_on "Book Tour"

      expect(page).to have_text("Booking was successful")
      expect(Booking.last.user).to eq(tourist)
      expect(Booking.last.tour).to eq(tour)
    end

    context "when user is not signed in" do
      it "redirects to sign in page" do
        visit tour_path(tour)
        click_on "Book Tour"

        expect(page).to have_current_path(new_user_session_path, ignore_query: true)
      end
    end
  end

  describe "Managing bookings" do
    before do
      booking
      sign_in_user(tourist, password:)
      visit manage_booking_path(booking, email: tourist.email)
    end

    it_behaves_like "an accessible page"

    it "displays booking details" do
      expect(page).to have_text(tour.title)
      expect(page).to have_text(booking.status.upcase)
    end

    it "allows cancelling a booking" do
      click_on "Cancel Booking"

      expect(page).to have_text("Booking was cancelled")
      expect(booking.reload.status).to eq("cancelled")
    end

    context "when booking is cancelled" do
      before do
        booking.update(status: "cancelled")
        visit manage_booking_path(booking, email: tourist.email)
      end

      it "shows cancelled status" do
        expect(page).to have_text("CANCELLED")
      end
    end
  end

  describe "Viewing bookings as a guide" do
    before do
      FactoryBot.create_list(:booking, 3, tour:)
      sign_in_user(guide, password:)
      visit admin_bookings_path
    end

    it "displays all bookings for the guide's tours" do
      expect(page).to have_css("tr", minimum: 3)
    end
  end
end
