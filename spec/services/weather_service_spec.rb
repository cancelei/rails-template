require "rails_helper"

RSpec.describe WeatherService do
  describe ".fetch_forecast" do
    let(:latitude) { -41.2865 }
    let(:longitude) { 174.7762 }

    let(:weather_response) do
      {
        "daily" => (0..7).map do |i|
          {
            "dt" => (Date.current + i.days).to_time.to_i,
            "temp" => { "min" => 10 + i, "max" => 20 + i },
            "weather" => [{ "description" => "clear sky", "icon" => "01d" }],
            "pop" => 0.1 + (i * 0.05),
            "wind_speed" => 5 + i
          }
        end
      }
    end

    before do
      # Mock the weather API response
      stub_request(:get, "https://api.openweathermap.org/data/2.5/onecall")
        .with(
          query: hash_including(
            lat: latitude.to_s,
            lon: longitude.to_s
          )
        )
        .to_return(
          status: 200,
          body: weather_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "with valid API key" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return("test_api_key")
      end

      it "returns 8 days of forecast data" do
        result = described_class.fetch_forecast(latitude, longitude)
        expect(result).to be_an(Array)
        expect(result.length).to eq(8)
      end

      it "includes all required fields" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast).to include(
          :forecast_date,
          :min_temp,
          :max_temp,
          :description,
          :icon,
          :pop,
          :wind_speed
        )
      end

      it "correctly parses forecast dates" do
        result = described_class.fetch_forecast(latitude, longitude)

        expect(result.first[:forecast_date]).to eq(Date.current)
        expect(result.last[:forecast_date]).to eq(Date.current + 7.days)
      end

      it "correctly parses temperature values" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast[:min_temp]).to eq(10)
        expect(forecast[:max_temp]).to eq(20)
      end

      it "correctly parses weather description" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast[:description]).to eq("clear sky")
        expect(forecast[:icon]).to eq("01d")
      end

      it "correctly parses precipitation probability" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast[:pop]).to be_between(0, 1)
        expect(forecast[:pop]).to eq(0.1)
      end

      it "correctly parses wind speed" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast[:wind_speed]).to be >= 0
        expect(forecast[:wind_speed]).to eq(5)
      end
    end

    context "without API key" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return(nil)
      end

      it "returns empty array" do
        result = described_class.fetch_forecast(latitude, longitude)
        expect(result).to eq([])
      end

      it "does not make API request" do
        described_class.fetch_forecast(latitude, longitude)

        expect(WebMock).not_to have_requested(:get, /api.openweathermap.org/)
      end
    end

    context "when API returns error" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return("test_api_key")

        stub_request(:get, "https://api.openweathermap.org/data/2.5/onecall")
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "returns empty array" do
        result = described_class.fetch_forecast(latitude, longitude)
        expect(result).to eq([])
      end
    end

    context "when API returns 401 (unauthorized)" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return("invalid_key")

        stub_request(:get, "https://api.openweathermap.org/data/2.5/onecall")
          .to_return(
            status: 401,
            body: { message: "Invalid API key" }.to_json
          )
      end

      it "returns empty array" do
        result = described_class.fetch_forecast(latitude, longitude)
        expect(result).to eq([])
      end
    end

    context "when API returns 429 (rate limit)" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return("test_api_key")

        stub_request(:get, "https://api.openweathermap.org/data/2.5/onecall")
          .to_return(
            status: 429,
            body: { message: "Rate limit exceeded" }.to_json
          )
      end

      it "returns empty array" do
        result = described_class.fetch_forecast(latitude, longitude)
        expect(result).to eq([])
      end
    end

    context "when network timeout occurs" do
      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return("test_api_key")

        stub_request(:get, "https://api.openweathermap.org/data/2.5/onecall")
          .to_timeout
      end

      it "raises timeout error" do
        expect do
          described_class.fetch_forecast(latitude, longitude)
        end.to raise_error(Net::OpenTimeout)
      end
    end

    context "with extreme weather conditions" do
      let(:extreme_weather_response) do
        {
          "daily" => [{
            "dt" => Date.current.to_time.to_i,
            "temp" => { "min" => -20, "max" => 40 },
            "weather" => [{ "description" => "heavy thunderstorm", "icon" => "11d" }],
            "pop" => 0.95,
            "wind_speed" => 25
          }]
        }
      end

      before do
        allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return("test_api_key")

        stub_request(:get, "https://api.openweathermap.org/data/2.5/onecall")
          .to_return(
            status: 200,
            body: extreme_weather_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles extreme temperature values" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast[:min_temp]).to eq(-20)
        expect(forecast[:max_temp]).to eq(40)
      end

      it "handles high precipitation probability" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast[:pop]).to eq(0.95)
      end

      it "handles high wind speeds" do
        result = described_class.fetch_forecast(latitude, longitude)
        forecast = result.first

        expect(forecast[:wind_speed]).to eq(25)
      end
    end
  end
end
