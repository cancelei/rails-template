require "rails_helper"

RSpec.describe RefreshWeatherJob do
  let(:guide) { create(:user, role: :guide) }

  let(:mock_forecast) do
    [
      {
        forecast_date: Date.current,
        min_temp: 10,
        max_temp: 20,
        description: "clear sky",
        icon: "01d",
        pop: 0.1,
        wind_speed: 5
      },
      {
        forecast_date: Date.current + 1.day,
        min_temp: 12,
        max_temp: 22,
        description: "partly cloudy",
        icon: "02d",
        pop: 0.2,
        wind_speed: 6
      }
    ]
  end

  before do
    # Mock WeatherService to avoid real API calls
    allow(WeatherService).to receive(:fetch_forecast).and_return(mock_forecast)
  end

  describe "#perform" do
    context "with tours starting within 8 days" do
      let!(:tour_near) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 3.days.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      let!(:tour_far) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 10.days.from_now,
               latitude: -45.8788,
               longitude: 170.5028
              )
      end

      it "fetches weather for tours starting within 8 days" do
        described_class.perform_now

        expect(WeatherService).to have_received(:fetch_forecast)
          .with(tour_near.latitude, tour_near.longitude)
      end

      it "does not fetch weather for tours starting after 8 days" do
        described_class.perform_now

        expect(WeatherService).not_to have_received(:fetch_forecast)
          .with(tour_far.latitude, tour_far.longitude)
      end

      it "creates weather snapshots" do
        # 2 days of forecast
        expect do
          described_class.perform_now
        end.to change(WeatherSnapshot, :count).by(2)
      end

      it "stores correct weather data" do
        described_class.perform_now

        snapshot = WeatherSnapshot.find_by(tour: tour_near, forecast_date: Date.current)
        expect(snapshot.min_temp).to eq(10)
        expect(snapshot.max_temp).to eq(20)
        expect(snapshot.description).to eq("clear sky")
        expect(snapshot.icon).to eq("01d")
        expect(snapshot.pop).to eq(0.1)
        expect(snapshot.wind_speed).to eq(5)
      end

      it "updates existing weather snapshots" do
        # Create existing snapshot
        existing = create(:weather_snapshot,
                          tour: tour_near,
                          forecast_date: Date.current,
                          min_temp: 15,
                          max_temp: 25,
                          pop: 0.2
                         )

        described_class.perform_now

        existing.reload
        expect(existing.min_temp).to eq(10)  # Updated
        expect(existing.max_temp).to eq(20)  # Updated
        expect(existing.pop).to eq(0.1) # Updated
      end
    end

    context "with tours without coordinates" do
      let!(:tour_no_coords) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 3.days.from_now,
               latitude: nil,
               longitude: nil
              )
      end

      it "skips tours without coordinates" do
        described_class.perform_now

        expect(WeatherService).not_to have_received(:fetch_forecast)
      end

      it "does not create weather snapshots" do
        expect do
          described_class.perform_now
        end.not_to change(WeatherSnapshot, :count)
      end
    end

    context "with cancelled tours" do
      let!(:tour_cancelled) do
        create(:tour,
               guide:,
               status: :cancelled,
               starts_at: 3.days.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      it "skips cancelled tours" do
        described_class.perform_now

        expect(WeatherService).not_to have_received(:fetch_forecast)
      end
    end

    context "when weather changes significantly" do
      let!(:tour) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 3.days.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      let(:rainy_forecast) do
        [
          {
            forecast_date: Date.current,
            min_temp: 8,
            max_temp: 12,
            description: "heavy rain",
            icon: "10d",
            pop: 0.9, # 90% rain probability (was 10%)
            wind_speed: 15
          }
        ]
      end

      before do
        # Create existing snapshot with good weather
        create(:weather_snapshot,
               tour:,
               forecast_date: Date.current,
               min_temp: 10,
               max_temp: 20,
               description: "clear sky",
               pop: 0.1 # Was good weather
              )

        allow(WeatherService).to receive(:fetch_forecast).and_return(rainy_forecast)
      end

      it "detects significant weather change" do
        expect do
          described_class.perform_now
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("WeatherMailer", "weather_alert", "deliver_now", hash_including(args: [guide, tour, anything]))
      end

      it "updates the weather snapshot" do
        described_class.perform_now

        snapshot = WeatherSnapshot.find_by(tour:, forecast_date: Date.current)
        expect(snapshot.pop).to eq(0.9)
        expect(snapshot.description).to eq("heavy rain")
      end
    end

    context "when weather does not change significantly" do
      let!(:tour) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 3.days.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      before do
        # Create existing snapshot with similar weather
        create(:weather_snapshot,
               tour:,
               forecast_date: Date.current,
               pop: 0.15 # Similar to mock (0.1)
              )
      end

      it "does not send weather alert" do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end

    context "when API call fails" do
      let!(:tour) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 3.days.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      before do
        allow(WeatherService).to receive(:fetch_forecast).and_return([])
      end

      it "handles empty forecast gracefully" do
        expect do
          described_class.perform_now
        end.not_to raise_error
      end

      it "does not create weather snapshots" do
        expect do
          described_class.perform_now
        end.not_to change(WeatherSnapshot, :count)
      end
    end

    context "when API raises exception" do
      let!(:tour) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 3.days.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      before do
        allow(WeatherService).to receive(:fetch_forecast).and_raise(StandardError, "API error")
        allow(Rails.logger).to receive(:error)
      end

      it "handles exception gracefully" do
        expect do
          described_class.perform_now
        end.not_to raise_error
      end
    end

    context "with multiple tours" do
      let!(:tour1) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 2.days.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      let!(:tour2) do
        create(:tour,
               guide:,
               status: :scheduled,
               starts_at: 5.days.from_now,
               latitude: -36.8485,
               longitude: 174.7633
              )
      end

      it "fetches weather for all eligible tours" do
        described_class.perform_now

        expect(WeatherService).to have_received(:fetch_forecast).twice
      end

      it "creates snapshots for all tours" do
        # 2 tours × 2 forecast days
        expect do
          described_class.perform_now
        end.to change(WeatherSnapshot, :count).by(4)
      end
    end

    context "with ongoing tours" do
      let!(:ongoing_tour) do
        create(:tour,
               guide:,
               status: :ongoing,
               starts_at: 1.hour.ago,
               ends_at: 2.hours.from_now,
               latitude: -41.2865,
               longitude: 174.7762
              )
      end

      it "includes ongoing tours" do
        described_class.perform_now

        expect(WeatherService).to have_received(:fetch_forecast)
          .with(ongoing_tour.latitude, ongoing_tour.longitude)
      end
    end

    context "edge case: tour starting exactly 8 days from now" do
      let!(:tour_edge) do
        Timecop.freeze do
          create(:tour,
                 guide:,
                 status: :scheduled,
                 starts_at: 8.days.from_now,
                 latitude: -41.2865,
                 longitude: 174.7762
                )
        end
      end

      it "includes tour starting exactly 8 days from now" do
        described_class.perform_now

        expect(WeatherService).to have_received(:fetch_forecast)
      end
    end
  end
end
