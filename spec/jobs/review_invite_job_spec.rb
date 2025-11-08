require "rails_helper"

RSpec.describe ReviewInviteJob do
  describe "#perform" do
    it "successfully enqueues the job" do
      expect do
        described_class.perform_later
      end.to have_enqueued_job(described_class)
    end

    it "executes without errors" do
      expect do
        described_class.new.perform
      end.not_to raise_error
    end
  end

  describe "job queue" do
    it "is enqueued to default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
