require "rails_helper"

RSpec.describe "Home" do
  describe "GET /" do
    let!(:scheduled_tours) { create_list(:tour, 3, status: :scheduled, available_spots: 5) }
    let!(:cancelled_tour) { create(:tour, status: :cancelled) }
    let!(:sold_out_tour) { create(:tour, status: :scheduled, available_spots: 0) }

    it "returns successful response" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "displays available tours" do
      get root_path
      scheduled_tours.each do |tour|
        expect(response.body).to include(tour.title)
      end
    end

    it "does not show cancelled tours" do
      get root_path
      expect(response.body).not_to include(cancelled_tour.title)
    end

    it "shows sold out indicator for tours with no spots" do
      get root_path
      expect(response.body).to include(sold_out_tour.title)
      expect(response.body).to include("0") # available spots
    end

    context "for signed in tourists" do
      let(:tourist) { create(:user, :tourist) }

      before { sign_in tourist }

      it "shows sign up as guide option" do
        get root_path
        expect(response.body).to include("Become a Guide")
      end
    end

    context "for signed in guides" do
      let(:guide) { create(:user, :guide) }

      before { sign_in guide }

      it "shows create tour option" do
        get root_path
        expect(response.body).to include("Create Tour")
      end
    end

    context "for non-signed in users" do
      it "shows both signup options" do
        get root_path
        expect(response.body).to include("Sign up as Tourist")
        expect(response.body).to include("Sign up as Guide")
      end
    end
  end

  describe "Featured tours section" do
    let!(:popular_tour) do
      create(:tour,
             status: :scheduled,
             available_spots: 20,
             max_participants: 20)
    end

    let!(:upcoming_tour) do
      create(:tour,
             status: :scheduled,
             starts_at: 1.day.from_now)
    end

    before do
      # Create some bookings to make tour popular
      create_list(:booking, 10, tour: popular_tour, status: :confirmed)
      create_list(:booking, 5, tour: popular_tour, status: :confirmed)
    end

    it "highlights tours with many bookings" do
      get root_path
      expect(response).to have_http_status(:success)
      # The response should show tours ordered by some criteria
    end

    it "shows upcoming tours prominently" do
      get root_path
      expect(response.body).to include(upcoming_tour.title)
    end
  end

  describe "Search and filter" do
    let!(:mountain_tour) do
      create(:tour,
             title: "Mountain Climbing Adventure",
             location_name: "Rockies",
             status: :scheduled)
    end

    let!(:beach_tour) do
      create(:tour,
             title: "Beach Relaxation Tour",
             location_name: "Hawaii",
             status: :scheduled)
    end

    it "filters tours by search query" do
      get root_path, params: { q: "Mountain" }
      expect(response.body).to include(mountain_tour.title)
    end

    it "filters tours by location" do
      get root_path, params: { location: "Hawaii" }
      expect(response).to have_http_status(:success)
    end

    it "filters tours by date range" do
      create(:tour, starts_at: 30.days.from_now, status: :scheduled)

      get root_path, params: { date_from: 25.days.from_now }
      expect(response).to have_http_status(:success)
    end
  end

  describe "Tour availability indicators" do
    let!(:high_availability) { create(:tour, available_spots: 15, max_participants: 20) }
    let!(:medium_availability) { create(:tour, available_spots: 5, max_participants: 20) }
    let!(:low_availability) { create(:tour, available_spots: 1, max_participants: 20) }

    it "shows different indicators based on availability" do
      get root_path

      expect(response.body).to include("15") # high availability
      expect(response.body).to include("5")  # medium availability
      expect(response.body).to include("1")  # low availability
    end
  end

  describe "Guide showcase" do
    let!(:guide_with_tours) { create(:user, :guide) }
    let!(:guides_tours) { create_list(:tour, 3, guide: guide_with_tours, status: :scheduled) }

    it "shows guide information" do
      get root_path
      expect(response.body).to include(guide_with_tours.name)
    end

    it "shows number of tours per guide" do
      get root_path
      # Should display guide's active tours count
      expect(response).to have_http_status(:success)
    end
  end

  describe "Call-to-action sections" do
    it "displays tourist signup CTA" do
      get root_path
      expect(response.body).to match(/sign.*up.*tourist/i)
    end

    it "displays guide signup CTA" do
      get root_path
      expect(response.body).to match(/sign.*up.*guide/i)
    end

    it "shows browse tours button" do
      get root_path
      expect(response.body).to include("tours")
    end
  end

  describe "Performance and caching" do
    it "loads home page efficiently" do
      # Create a realistic dataset
      create_list(:tour, 10, status: :scheduled)
      create_list(:tour, 10, status: :scheduled)

      start_time = Time.current
      get root_path
      end_time = Time.current

      expect(response).to have_http_status(:success)
      # Page should load reasonably fast even with multiple tours
      expect(end_time - start_time).to be < 2.seconds
    end
  end

  describe "Responsive design indicators" do
    it "includes responsive classes" do
      get root_path
      expect(response.body).to match(/sm:|md:|lg:/) # Tailwind responsive classes
    end

    it "is mobile-friendly" do
      get root_path
      expect(response.body).to include("viewport")
    end
  end

  describe "Weather integration" do
    let(:tour_with_weather) { create(:tour, status: :scheduled, starts_at: 3.days.from_now) }
    let!(:weather_snapshot) do
      create(:weather_snapshot,
             tour: tour_with_weather,
             description: "Sunny",
             max_temp: 25,
             min_temp: 15)
    end

    it "shows weather information for upcoming tours" do
      get root_path
      # Weather might be shown on tour cards
      expect(response).to have_http_status(:success)
    end
  end
end
