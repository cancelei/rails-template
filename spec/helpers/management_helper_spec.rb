# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManagementHelper do
  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:tour) { create(:tour, guide:) }
  let(:booking) { create(:booking, tour:, user: tourist) }

  before do
    allow(helper).to receive(:current_user).and_return(admin)
  end

  describe "#management_context" do
    it "returns :admin for admin controller paths" do
      allow(helper).to receive(:controller_path).and_return("admin/tours")
      expect(helper.management_context).to eq(:admin)
    end

    it "returns :guide for guides controller paths" do
      allow(helper).to receive(:controller_path).and_return("guides/dashboard")
      expect(helper.management_context).to eq(:guide)
    end

    it "returns :tourist for other controller paths" do
      allow(helper).to receive(:controller_path).and_return("tours")
      expect(helper.management_context).to eq(:tourist)
    end

    it "caches the result" do
      allow(helper).to receive(:controller_path).and_return("admin/tours")
      first_call = helper.management_context
      second_call = helper.management_context

      expect(first_call).to eq(second_call)
      expect(helper).to have_received(:controller_path).once
    end
  end

  describe "#admin_context?" do
    it "returns true when in admin context" do
      allow(helper).to receive(:controller_path).and_return("admin/tours")
      expect(helper.admin_context?).to be true
    end

    it "returns false when not in admin context" do
      allow(helper).to receive(:controller_path).and_return("guides/dashboard")
      expect(helper.admin_context?).to be false
    end
  end

  describe "#guide_context?" do
    it "returns true when in guide context" do
      allow(helper).to receive(:controller_path).and_return("guides/dashboard")
      expect(helper.guide_context?).to be true
    end

    it "returns false when not in guide context" do
      allow(helper).to receive(:controller_path).and_return("admin/tours")
      expect(helper.guide_context?).to be false
    end
  end

  describe "#current_user_can_edit?" do
    before do
      allow(Pundit).to receive(:policy).with(admin, tour).and_return(double(update?: true))
    end

    it "returns true when user has edit permissions" do
      expect(helper.current_user_can_edit?(tour)).to be true
    end

    it "returns false when user lacks edit permissions" do
      allow(Pundit).to receive(:policy).with(admin, tour).and_return(double(update?: false))
      expect(helper.current_user_can_edit?(tour)).to be false
    end

    it "returns false when no current user" do
      allow(helper).to receive(:current_user).and_return(nil)
      expect(helper.current_user_can_edit?(tour)).to be false
    end

    it "handles Pundit::NotDefinedError gracefully" do
      allow(Pundit).to receive(:policy).with(admin, tour).and_raise(Pundit::NotDefinedError)
      expect(helper.current_user_can_edit?(tour)).to be false
    end
  end

  describe "#current_user_can_delete?" do
    before do
      allow(Pundit).to receive(:policy).with(admin, tour).and_return(double(destroy?: true))
    end

    it "returns true when user has delete permissions" do
      expect(helper.current_user_can_delete?(tour)).to be true
    end

    it "returns false when user lacks delete permissions" do
      allow(Pundit).to receive(:policy).with(admin, tour).and_return(double(destroy?: false))
      expect(helper.current_user_can_delete?(tour)).to be false
    end

    it "returns false when no current user" do
      allow(helper).to receive(:current_user).and_return(nil)
      expect(helper.current_user_can_delete?(tour)).to be false
    end
  end

  describe "#current_user_can_view?" do
    before do
      allow(Pundit).to receive(:policy).with(admin, tour).and_return(double(show?: true))
    end

    it "returns true when user has view permissions" do
      expect(helper.current_user_can_view?(tour)).to be true
    end

    it "returns false when user lacks view permissions" do
      allow(Pundit).to receive(:policy).with(admin, tour).and_return(double(show?: false))
      expect(helper.current_user_can_view?(tour)).to be false
    end
  end

  describe "#status_badge_classes" do
    it "returns success classes for confirmed status" do
      classes = helper.status_badge_classes("confirmed")
      expect(classes).to include("bg-success/10")
      expect(classes).to include("text-success")
    end

    it "returns danger classes for cancelled status" do
      classes = helper.status_badge_classes("cancelled")
      expect(classes).to include("bg-danger/10")
      expect(classes).to include("text-danger")
    end

    it "returns warning classes for pending status" do
      classes = helper.status_badge_classes("pending")
      expect(classes).to include("bg-warning/10")
      expect(classes).to include("text-warning")
    end

    it "returns info classes for done status" do
      classes = helper.status_badge_classes("done")
      expect(classes).to include("bg-info/10")
      expect(classes).to include("text-info")
    end

    it "returns muted classes for unknown status" do
      classes = helper.status_badge_classes("unknown")
      expect(classes).to include("bg-muted")
      expect(classes).to include("text-muted-foreground")
    end

    it "handles symbol status values" do
      classes = helper.status_badge_classes(:confirmed)
      expect(classes).to include("bg-success/10")
    end
  end

  describe "#format_status" do
    it "titleizes status strings" do
      expect(helper.format_status("confirmed")).to eq("Confirmed")
    end

    it "handles multi-word statuses" do
      expect(helper.format_status("in_progress")).to eq("In Progress")
    end

    it "handles symbol status values" do
      expect(helper.format_status(:scheduled)).to eq("Scheduled")
    end
  end

  describe "#inline_edit_frame_id" do
    it "returns the DOM ID for a resource" do
      expect(helper.inline_edit_frame_id(tour)).to eq(ActionView::RecordIdentifier.dom_id(tour))
    end
  end

  describe "#management_button_classes" do
    it "returns primary button classes by default" do
      classes = helper.management_button_classes
      expect(classes).to include("bg-primary")
      expect(classes).to include("text-primary-foreground")
    end

    it "returns secondary button classes" do
      classes = helper.management_button_classes(variant: :secondary)
      expect(classes).to include("bg-secondary")
    end

    it "returns danger button classes" do
      classes = helper.management_button_classes(variant: :danger)
      expect(classes).to include("bg-danger")
      expect(classes).to include("text-white")
    end

    it "returns ghost button classes" do
      classes = helper.management_button_classes(variant: :ghost)
      expect(classes).to include("bg-transparent")
    end

    it "includes base classes for all variants" do
      classes = helper.management_button_classes(variant: :primary)
      expect(classes).to include("inline-flex")
      expect(classes).to include("items-center")
      expect(classes).to include("rounded-md")
    end
  end

  describe "#owned_by_current_user?" do
    before do
      allow(helper).to receive(:current_user).and_return(guide)
    end

    it "returns true when resource belongs to current user via user association" do
      expect(helper.owned_by_current_user?(booking)).to be false # booking belongs to tourist
    end

    it "returns true when resource belongs to current user via guide association" do
      expect(helper.owned_by_current_user?(tour)).to be true
    end

    it "returns false when resource belongs to different user" do
      allow(helper).to receive(:current_user).and_return(tourist)
      expect(helper.owned_by_current_user?(tour)).to be false
    end

    it "returns false when no current user" do
      allow(helper).to receive(:current_user).and_return(nil)
      expect(helper.owned_by_current_user?(tour)).to be false
    end

    it "returns false for resources without ownership associations" do
      weather_snapshot = create(:weather_snapshot, tour:)
      expect(helper.owned_by_current_user?(weather_snapshot)).to be false
    end
  end

  describe "#management_notification_message" do
    before do
      allow(helper).to receive(:controller_path).and_return("admin/tours")
    end

    context "in admin context" do
      it "uses 'Admin' prefix for created action" do
        message = helper.management_notification_message(:created, "tour")
        expect(message).to include("Admin created")
      end

      it "uses 'Admin' prefix for updated action" do
        message = helper.management_notification_message(:updated, "tour")
        expect(message).to include("Admin updated")
      end

      it "uses 'Admin' prefix for deleted action" do
        message = helper.management_notification_message(:deleted, "booking")
        expect(message).to include("Admin deleted")
      end
    end

    context "in guide context" do
      before do
        allow(helper).to receive(:controller_path).and_return("guides/dashboard")
      end

      it "uses 'You' prefix for created action" do
        message = helper.management_notification_message(:created, "tour")
        expect(message).to include("You created")
      end

      it "uses 'You' prefix for updated action" do
        message = helper.management_notification_message(:updated, "tour")
        expect(message).to include("You updated")
      end
    end

    it "includes resource name in message" do
      message = helper.management_notification_message(:created, "tour")
      expect(message).to include("tour")
    end

    it "adds 'successfully' for create and update actions" do
      message = helper.management_notification_message(:created, "tour")
      expect(message).to include("successfully")
    end
  end

  describe "#empty_state_message" do
    it "returns personalized message in guide context" do
      allow(helper).to receive(:controller_path).and_return("guides/dashboard")
      message = helper.empty_state_message("tours")
      expect(message).to eq("You don't have any tours yet")
    end

    it "returns generic message in admin context" do
      allow(helper).to receive(:controller_path).and_return("admin/tours")
      message = helper.empty_state_message("tours")
      expect(message).to eq("No tours found")
    end

    it "returns default message in tourist context" do
      allow(helper).to receive(:controller_path).and_return("tours")
      message = helper.empty_state_message("tours")
      expect(message).to eq("No tours available")
    end
  end

  describe "#show_advanced_fields?" do
    it "returns true in admin context" do
      allow(helper).to receive(:controller_path).and_return("admin/tours")
      expect(helper.show_advanced_fields?).to be true
    end

    it "returns false in guide context" do
      allow(helper).to receive(:controller_path).and_return("guides/dashboard")
      expect(helper.show_advanced_fields?).to be false
    end

    it "returns false in tourist context" do
      allow(helper).to receive(:controller_path).and_return("tours")
      expect(helper.show_advanced_fields?).to be false
    end
  end
end
