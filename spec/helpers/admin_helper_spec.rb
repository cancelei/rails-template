require "rails_helper"

RSpec.describe AdminHelper do
  describe "#admin_page_title" do
    it "sets the page title" do
      helper.admin_page_title("Test Page")
      expect(helper.content_for(:page_title)).to eq("Test Page")
    end
  end

  describe "#status_badge" do
    context "with booking type" do
      it "returns pending badge for pending status" do
        result = helper.status_badge(:pending, type: :booking)
        expect(result).to include("bg-yellow-100")
        expect(result).to include("Pending")
      end

      it "returns confirmed badge for confirmed status" do
        result = helper.status_badge(:confirmed, type: :booking)
        expect(result).to include("bg-blue-100")
        expect(result).to include("Confirmed")
      end

      it "returns completed badge for completed status" do
        result = helper.status_badge(:completed, type: :booking)
        expect(result).to include("bg-green-100")
        expect(result).to include("Completed")
      end

      it "returns cancelled badge for cancelled status" do
        result = helper.status_badge(:cancelled, type: :booking)
        expect(result).to include("bg-red-100")
        expect(result).to include("Cancelled")
      end

      it "returns default badge for unknown status" do
        result = helper.status_badge(:unknown, type: :booking)
        expect(result).to include("bg-gray-100")
      end
    end

    context "with tour type" do
      it "returns scheduled badge" do
        result = helper.status_badge(:scheduled, type: :tour)
        expect(result).to include("bg-blue-100")
        expect(result).to include("Scheduled")
      end

      it "returns in_progress badge" do
        result = helper.status_badge(:in_progress, type: :tour)
        expect(result).to include("bg-yellow-100")
      end

      it "returns completed badge" do
        result = helper.status_badge(:done, type: :tour)
        expect(result).to include("bg-green-100")
      end

      it "returns cancelled badge" do
        result = helper.status_badge(:cancelled, type: :tour)
        expect(result).to include("bg-red-100")
      end
    end

    context "with user_role type" do
      it "returns admin badge" do
        result = helper.status_badge(:admin, type: :user_role)
        expect(result).to include("bg-purple-100")
        expect(result).to include("Admin")
      end

      it "returns guide badge" do
        result = helper.status_badge(:guide, type: :user_role)
        expect(result).to include("bg-blue-100")
        expect(result).to include("Guide")
      end

      it "returns tourist badge" do
        result = helper.status_badge(:tourist, type: :user_role)
        expect(result).to include("bg-green-100")
        expect(result).to include("Tourist")
      end
    end

    context "with default type" do
      it "returns default badge" do
        result = helper.status_badge(:active)
        expect(result).to include("bg-gray-100")
        expect(result).to include("Active")
      end
    end
  end

  describe "#admin_metric_card" do
    it "creates a metric card with default color" do
      result = helper.admin_metric_card(title: "Total Users", count: 100)
      expect(result).to include("Total Users")
      expect(result).to include("100")
      expect(result).to include("bg-blue-500")
    end

    it "creates a metric card with custom color" do
      result = helper.admin_metric_card(title: "Active Tours", count: 50, color: "green")
      expect(result).to include("Active Tours")
      expect(result).to include("50")
      expect(result).to include("bg-green-500")
    end

    it "supports all color options" do
      colors = %w[blue green purple orange red indigo]
      colors.each do |color|
        result = helper.admin_metric_card(title: "Test", count: 1, color:)
        expect(result).to include("bg-#{color}-500")
      end
    end
  end

  describe "#admin_action_button" do
    it "creates an action button with default styling" do
      result = helper.admin_action_button("Click Me", "/path/to/action")
      expect(result).to include("Click Me")
      expect(result).to include("/path/to/action")
      expect(result).to include("bg-indigo-600")
    end

    it "accepts custom options" do
      result = helper.admin_action_button("Custom", "/custom", class: "custom-class")
      expect(result).to include("custom-class")
      expect(result).to include("Custom")
    end
  end

  describe "#admin_delete_button" do
    it "creates a delete button with confirmation" do
      result = helper.admin_delete_button("Delete", "/delete/path")
      expect(result).to include("Delete")
      expect(result).to include("/delete/path")
      expect(result).to include("Are you sure?")
      expect(result).to include("text-red-600")
    end

    it "accepts custom options" do
      result = helper.admin_delete_button("Remove", "/remove", class: "custom-delete")
      expect(result).to include("custom-delete")
    end
  end
end
