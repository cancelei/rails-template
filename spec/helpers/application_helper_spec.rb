require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#primary_navigation_links" do
    context "when user is not signed in" do
      it "returns only home link" do
        links = helper.primary_navigation_links(nil)
        expect(links.length).to eq(1)
        expect(links.first[:label]).to eq("Home")
        expect(links.first[:path]).to eq(root_path)
      end
    end

    context "when user is a tourist" do
      let(:tourist) { build(:user, :tourist) }

      it "returns home and history links" do
        links = helper.primary_navigation_links(tourist)
        expect(links.length).to eq(2)
        expect(links.pluck(:label)).to contain_exactly("Home", "History")
      end

      it "includes correct paths" do
        links = helper.primary_navigation_links(tourist)
        expect(links.pluck(:path)).to include(root_path, history_path)
      end

      it "includes aria labels for accessibility" do
        links = helper.primary_navigation_links(tourist)
        expect(links.all? { |l| l[:aria_label].present? }).to be true
      end
    end

    context "when user is a guide" do
      let(:guide) { build(:user, :guide) }

      it "returns only home link" do
        links = helper.primary_navigation_links(guide)
        expect(links.length).to eq(1)
        expect(links.first[:label]).to eq("Home")
      end
    end

    context "when user is an admin" do
      let(:admin) { build(:user, :admin) }

      it "returns only home link" do
        links = helper.primary_navigation_links(admin)
        expect(links.length).to eq(1)
        expect(links.first[:label]).to eq("Home")
      end
    end
  end

  describe "#auth_navigation_data" do
    context "when user is signed in" do
      let(:user) { build(:user, :tourist, email: "test@example.com") }

      it "returns signed in state" do
        data = helper.auth_navigation_data(user)
        expect(data[:state]).to eq(:signed_in)
      end

      it "includes user email" do
        data = helper.auth_navigation_data(user)
        expect(data[:email]).to eq("test@example.com")
      end

      it "includes sign out details" do
        data = helper.auth_navigation_data(user)
        expect(data[:sign_out]).to be_present
        expect(data[:sign_out][:label]).to eq("Sign Out")
        expect(data[:sign_out][:path]).to eq(destroy_user_session_path)
        expect(data[:sign_out][:method]).to eq(:delete)
      end

      it "includes aria label for sign out" do
        data = helper.auth_navigation_data(user)
        expect(data[:sign_out][:aria_label]).to be_present
      end
    end

    context "when user is not signed in" do
      it "returns signed out state" do
        data = helper.auth_navigation_data(nil)
        expect(data[:state]).to eq(:signed_out)
      end

      it "includes sign in link" do
        data = helper.auth_navigation_data(nil)
        sign_in_link = data[:links].find { |l| l[:label] == "Sign In" }
        expect(sign_in_link).to be_present
        expect(sign_in_link[:path]).to eq(new_user_session_path)
      end

      it "includes become a guide link" do
        data = helper.auth_navigation_data(nil)
        guide_link = data[:links].find { |l| l[:label] == "Become a Guide" }
        expect(guide_link).to be_present
        expect(guide_link[:path]).to eq(become_a_guide_path)
      end

      it "includes sign up link" do
        data = helper.auth_navigation_data(nil)
        signup_link = data[:links].find { |l| l[:label] == "Sign Up" }
        expect(signup_link).to be_present
        expect(signup_link[:path]).to eq(new_tourist_registration_path)
      end

      it "all links have aria labels" do
        data = helper.auth_navigation_data(nil)
        expect(data[:links].all? { |l| l[:aria_label].present? }).to be true
      end
    end
  end
end
