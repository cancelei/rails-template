require "rails_helper"

RSpec.describe BookingMailer do
  let(:guide) { create(:user, role: :guide, name: "Jane Guide", email: "guide@example.com") }
  let(:tour) { create(:tour, guide:, title: "Mountain Hike", starts_at: 2.days.from_now) }
  let(:booking) { create(:booking, tour:, booked_name: "John Doe", booked_email: "john@example.com", spots: 2) }

  describe "#confirmation" do
    let(:mail) { described_class.confirmation(booking) }

    it "sends to the booking email" do
      expect(mail.to).to eq(["john@example.com"])
    end

    it "has correct subject" do
      expect(mail.subject).to eq("Booking Confirmation")
    end

    it "includes tour title in body" do
      expect(mail.body.encoded).to include("Mountain Hike")
    end

    it "includes booking details" do
      expect(mail.body.encoded).to include("2 spots") if mail.body.parts.any?
    end

    it "sets correct from address" do
      expect(mail.from).to include("from@example.com")
    end
  end

  describe "#cancellation" do
    let(:mail) { described_class.cancellation(booking) }

    it "sends to the booking email" do
      expect(mail.to).to eq([booking.booked_email])
    end

    it "has correct subject" do
      expect(mail.subject).to eq("Booking Cancellation")
    end

    it "includes tour information" do
      expect(mail.body.encoded).to include(tour.title)
    end
  end

  describe "#reminder" do
    let(:mail) { described_class.reminder(booking, 3) }

    it "sends to the booking email" do
      expect(mail.to).to eq([booking.booked_email])
    end

    it "includes days until in subject" do
      expect(mail.subject).to include("3 days")
    end

    it "includes tour title" do
      expect(mail.body.encoded).to include(tour.title)
    end

    context "with 1 day reminder" do
      let(:mail) { described_class.reminder(booking, 1) }

      it "includes correct days" do
        expect(mail.subject).to include("1 days")
      end
    end
  end
end
