require "rails_helper"

RSpec.describe EmailService do
  describe ".send_email" do
    let(:recipient) { "user@example.com" }
    let(:template) { "booking_confirmation" }
    let(:data) do
      {
        subject: "Booking Confirmed",
        booking_id: 123,
        tour_title: "City Tour"
      }
    end

    it "creates an EmailLog record" do
      expect do
        described_class.send_email(recipient, template, data)
      end.to change(EmailLog, :count).by(1)
    end

    it "stores all email details" do
      log = described_class.send_email(recipient, template, data)

      expect(log.recipient).to eq("user@example.com")
      expect(log.subject).to eq("Booking Confirmed")
      expect(log.template).to eq("booking_confirmation")
      # payload_json is stored as JSON string, need to parse
      parsed_payload = JSON.parse(log.payload_json)
      expect(parsed_payload["booking_id"]).to eq(123)
      expect(parsed_payload["tour_title"]).to eq("City Tour")
    end

    it "defaults to sent status" do
      log = described_class.send_email(recipient, template, data)
      expect(log.status).to eq("sent")
    end

    it "returns the created EmailLog" do
      log = described_class.send_email(recipient, template, data)
      expect(log).to be_a(EmailLog)
      expect(log).to be_persisted
    end

    context "with complex data" do
      it "stores nested JSON data" do
        complex_data = {
          subject: "Booking Reminder",
          booking: {
            id: 123,
            tour: {
              title: "City Tour",
              guide: "Jane Doe"
            },
            spots: 2
          }
        }

        log = described_class.send_email(recipient, template, complex_data)
        parsed = JSON.parse(log.payload_json)

        expect(parsed["booking"]["id"]).to eq(123)
        expect(parsed["booking"]["tour"]["title"]).to eq("City Tour")
      end
    end

    context "when EMAILIT_SANDBOX is enabled" do
      before do
        allow(ENV).to receive(:[]).with("EMAILIT_SANDBOX").and_return("true")
      end

      it "sets status to sandbox" do
        log = described_class.send_email(recipient, template, data)
        expect(log.status).to eq("sandbox")
      end
    end

    context "when EMAILIT_SANDBOX is disabled" do
      before do
        allow(ENV).to receive(:[]).with("EMAILIT_SANDBOX").and_return(nil)
      end

      it "sets status to sent" do
        log = described_class.send_email(recipient, template, data)
        expect(log.status).to eq("sent")
      end
    end

    context "error handling" do
      context "when database save fails" do
        before do
          allow(EmailLog).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
        end

        it "raises the error" do
          expect do
            described_class.send_email(recipient, template, data)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "email delivery tracking" do
      it "records timestamp" do
        Timecop.freeze do
          log = described_class.send_email(recipient, template, data)
          expect(log.created_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context "audit trail compliance" do
      it "includes all required audit fields" do
        log = described_class.send_email(recipient, template, data)

        expect(log).to have_attributes(
          recipient: be_present,
          subject: be_present,
          template: be_present,
          status: be_present,
          created_at: be_present
        )
      end
    end

    context "bulk email sending" do
      it "can log multiple emails efficiently" do
        expect do
          10.times do |i|
            described_class.send_email(
              "user#{i}@example.com",
              "test",
              { subject: "Test #{i}", index: i }
            )
          end
        end.to change(EmailLog, :count).by(10)
      end
    end
  end
end
