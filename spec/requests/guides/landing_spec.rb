require "rails_helper"

RSpec.describe "Guides::Landing" do
  let!(:guides) { create_list(:user, 5, :guide) }
  let!(:tours) { create_list(:tour, 10, guide: guides.first) }
  let!(:bookings) { create_list(:booking, 15, tour: tours.first) }
  let!(:guide_profiles) { guides.map { |guide| create(:guide_profile, user: guide, rating_cached: 4.5) } }

  describe "GET /guides" do
    it "returns http success" do
      get guides_landing_path
      expect(response).to have_http_status(:success)
    end

    it "displays total guides count" do
      get guides_landing_path
      expect(assigns(:total_guides)).to eq(5)
    end

    it "displays total tours count" do
      get guides_landing_path
      expect(assigns(:total_tours)).to eq(10)
    end

    it "displays total bookings count" do
      get guides_landing_path
      expect(assigns(:total_bookings)).to eq(15)
    end

    it "calculates average rating from guide profiles" do
      get guides_landing_path
      expect(assigns(:average_rating)).to eq(4.5)
    end

    context "when no ratings exist" do
      before do
        GuideProfile.update_all(rating_cached: nil)
      end

      it "defaults to 4.8 rating" do
        get guides_landing_path
        expect(assigns(:average_rating)).to eq(4.8)
      end
    end

    context "when user is authenticated" do
      let(:user) { create(:user, :tourist) }

      before { sign_in user }

      it "still returns http success" do
        get guides_landing_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
