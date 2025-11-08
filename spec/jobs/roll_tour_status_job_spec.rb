require "rails_helper"

RSpec.describe RollTourStatusJob do
  describe "#perform" do
    context "transitioning to ongoing" do
      let!(:tour) do
        create(:tour,
               status: :scheduled,
               starts_at: 1.minute.ago,
               ends_at: 1.hour.from_now
              )
      end

      it "changes status from scheduled to ongoing" do
        expect do
          described_class.perform_now
          tour.reload
        end.to change(tour, :status).from("scheduled").to("ongoing")
      end
    end

    context "transitioning to done" do
      let!(:tour) do
        create(:tour,
               status: :ongoing,
               starts_at: 2.hours.ago,
               ends_at: 1.minute.ago
              )
      end

      it "changes status from ongoing to done" do
        expect do
          described_class.perform_now
          tour.reload
        end.to change(tour, :status).from("ongoing").to("done")
      end
    end

    context "with multiple tours needing updates" do
      before do
        # Tour that should become ongoing
        create(:tour,
               status: :scheduled,
               starts_at: 1.minute.ago,
               ends_at: 1.hour.from_now
              )

        # Tour that should become done
        create(:tour,
               status: :ongoing,
               starts_at: 2.hours.ago,
               ends_at: 1.minute.ago
              )

        # Tour that should stay scheduled
        create(:tour,
               status: :scheduled,
               starts_at: 1.hour.from_now,
               ends_at: 2.hours.from_now
              )

        # Tour that should stay ongoing
        create(:tour,
               status: :ongoing,
               starts_at: 1.hour.ago,
               ends_at: 1.hour.from_now
              )
      end

      it "updates all eligible tours in one pass" do
        # NOTE: ongoing count stays the same (+1 from scheduled, -1 to done)
        expect do
          described_class.perform_now
        end.to change { Tour.done.count }.by(1)
                                         .and change { Tour.scheduled.count }.by(-1)
      end

      it "leaves unchanged tours alone" do
        # Should still have 1 scheduled and 2 ongoing (1 transitioned, 1 stayed)
        described_class.perform_now
        expect(Tour.scheduled.count).to eq(1)
        expect(Tour.ongoing.count).to eq(2)
      end
    end

    context "with cancelled tours" do
      let!(:tour) do
        create(:tour,
               status: :cancelled,
               starts_at: 1.minute.ago,
               ends_at: 1.hour.from_now
              )
      end

      it "does not change cancelled tours" do
        expect do
          described_class.perform_now
          tour.reload
        end.not_to change(tour, :status)
      end

      it "keeps tour as cancelled" do
        described_class.perform_now
        tour.reload
        expect(tour.status).to eq("cancelled")
      end
    end

    context "edge case: starts_at exactly Time.current" do
      let!(:tour) do
        Timecop.freeze do
          create(:tour,
                 status: :scheduled,
                 starts_at: Time.current,
                 ends_at: 1.hour.from_now
                )
        end
      end

      it "transitions to ongoing" do
        expect do
          described_class.perform_now
          tour.reload
        end.to change(tour, :status).to("ongoing")
      end
    end

    context "edge case: ends_at exactly Time.current" do
      let!(:tour) do
        Timecop.freeze do
          create(:tour,
                 status: :ongoing,
                 starts_at: 1.hour.ago,
                 ends_at: Time.current
                )
        end
      end

      it "does not transition to done (ends_at must be in past)" do
        Timecop.freeze(tour.ends_at) do
          expect do
            described_class.perform_now
            tour.reload
          end.not_to change(tour, :status)
        end
      end
    end

    context "when tour has past starts_at but future ends_at" do
      let!(:tour) do
        create(:tour,
               status: :scheduled,
               starts_at: 30.minutes.ago,
               ends_at: 30.minutes.from_now
              )
      end

      it "transitions to ongoing" do
        expect do
          described_class.perform_now
          tour.reload
        end.to change(tour, :status).to("ongoing")
      end
    end

    context "when tour ends_at just passed" do
      let!(:tour) do
        create(:tour,
               status: :ongoing,
               starts_at: 2.hours.ago,
               ends_at: 1.second.ago
              )
      end

      it "transitions to done" do
        expect do
          described_class.perform_now
          tour.reload
        end.to change(tour, :status).to("done")
      end
    end

    context "with tours in different time zones" do
      around do |example|
        Time.use_zone("Wellington") do
          example.run
        end
      end

      let!(:tour) do
        create(:tour,
               status: :scheduled,
               starts_at: 1.minute.ago,
               ends_at: 1.hour.from_now
              )
      end

      it "correctly handles time zone calculations" do
        expect do
          described_class.perform_now
          tour.reload
        end.to change(tour, :status).to("ongoing")
      end
    end

    context "when job runs twice in a row" do
      let!(:tour) do
        create(:tour,
               status: :scheduled,
               starts_at: 1.minute.ago,
               ends_at: 1.hour.from_now
              )
      end

      it "is idempotent" do
        described_class.perform_now
        tour.reload
        expect(tour.status).to eq("ongoing")

        # Run again
        expect do
          described_class.perform_now
          tour.reload
        end.not_to change(tour, :status)
      end
    end

    context "with very old tours" do
      let!(:old_done_tour) do
        create(:tour,
               status: :ongoing,
               starts_at: 30.days.ago,
               ends_at: 29.days.ago
              )
      end

      it "updates old tours to done" do
        expect do
          described_class.perform_now
          old_done_tour.reload
        end.to change(old_done_tour, :status).to("done")
      end
    end

    context "with no tours to update" do
      before do
        # Create tours that don't need updates
        create(:tour, status: :scheduled, starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)
        create(:tour, status: :ongoing, starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
        create(:tour, status: :done, starts_at: 2.hours.ago, ends_at: 1.hour.ago)
        create(:tour, status: :cancelled, starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
      end

      it "completes without errors" do
        expect do
          described_class.perform_now
        end.not_to raise_error
      end

      it "does not change any tour statuses" do
        scheduled_count = Tour.scheduled.count
        ongoing_count = Tour.ongoing.count
        done_count = Tour.done.count
        cancelled_count = Tour.cancelled.count

        described_class.perform_now

        expect(Tour.scheduled.count).to eq(scheduled_count)
        expect(Tour.ongoing.count).to eq(ongoing_count)
        expect(Tour.done.count).to eq(done_count)
        expect(Tour.cancelled.count).to eq(cancelled_count)
      end
    end

    context "performance with many tours" do
      before do
        # Create 50 tours needing status updates
        25.times do
          create(:tour,
                 status: :scheduled,
                 starts_at: 1.minute.ago,
                 ends_at: 1.hour.from_now
                )
        end

        25.times do
          create(:tour,
                 status: :ongoing,
                 starts_at: 2.hours.ago,
                 ends_at: 1.minute.ago
                )
        end
      end

      it "updates all tours efficiently" do
        # NOTE: ongoing count stays the same (+25 from scheduled, -25 to done)
        expect do
          described_class.perform_now
        end.to change { Tour.done.count }.by(25)
                                         .and change { Tour.scheduled.count }.by(-25)
      end
    end

    context "when tour has bookings" do
      let(:guide) { create(:user, role: :guide) }
      let(:tourist) { create(:user, role: :tourist) }

      let!(:tour) do
        create(:tour,
               guide:,
               status: :ongoing,
               starts_at: 2.hours.ago,
               ends_at: 1.minute.ago
              )
      end

      let!(:booking) { create(:booking, tour:, user: tourist) }

      it "transitions tour to done even with bookings" do
        expect do
          described_class.perform_now
          tour.reload
        end.to change(tour, :status).to("done")
      end

      it "does not affect booking status" do
        expect do
          described_class.perform_now
          booking.reload
        end.not_to change(booking, :status)
      end
    end
  end
end
