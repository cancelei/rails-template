require "rails_helper"

RSpec.describe "Comments" do
  describe "GET /create" do
    it "returns http success" do
      get "/comments/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /toggle_like" do
    it "returns http success" do
      get "/comments/toggle_like"
      expect(response).to have_http_status(:success)
    end
  end
end
