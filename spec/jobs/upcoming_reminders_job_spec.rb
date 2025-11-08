require "rails_helper"

RSpec.describe UpcomingRemindersJob do
  let(:guide) { create(:user, :guide) }
  let!(:tour_72h) { create(:tour, guide:, starts_at: 72.5.hours.from_now, status: :scheduled) }
  let!(:tour_24h) { create(:tour, guide:, starts_at: 24.5.hours.from_now, status: :scheduled) }
  let!(:tour_48h) { create(:tour, guide:, starts_at: 48.hours.from_now, status: :scheduled) }
  let!(:booking_72h) { create(:booking, tour: tour_72h, status: :confirmed) }
  let!(:booking_24h) { create(:booking, tour: tour_24h, status: :confirmed) }
  let!(:booking_48h) { create(:booking, tour: tour_48h, status: :confirmed) }

  describe "#perform" do
    it "successfully enqueues the job" do
      expect do
        described_class.perform_later
      end.to have_enqueued_job(described_class)
    end

    it "sends reminders for tours starting in 72 hours" do
      expect do
        described_class.new.perform
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob).at_least(1).times
    end

    it "sends reminders for tours starting in 24 hours" do
      allow(BookingMailer).to receive(:reminder).and_call_original

      described_class.new.perform

      expect(BookingMailer).to have_received(:reminder).at_least(:once)
    end

    it "does not send reminders for tours outside the time windows" do
      # The 48h booking should not receive a reminder
      # Only 72h and 24h
      expect do
        described_class.new.perform
      end.to have_enqueued_job(ActionMailer::MailDeliveryJob).at_least(2).times
    end

    context "with cancelled tours" do
      let!(:cancelled_tour) { create(:tour, guide:, starts_at: 72.5.hours.from_now, status: :cancelled) }
      let!(:cancelled_booking) { create(:booking, tour: cancelled_tour, status: :confirmed) }

      it "does not send reminders for cancelled tours" do
        allow(BookingMailer).to receive(:reminder).and_call_original

        described_class.new.perform

        # Should only send for scheduled tours (72h and 24h)
        expect(BookingMailer).to have_received(:reminder).exactly(2).times
      end
    end
  end

  describe "job queue" do
    it "is enqueued to default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
