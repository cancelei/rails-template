# == Schema Information
#
# Table name: email_logs
#
#  id                  :bigint           not null, primary key
#  payload_json        :text
#  recipient           :string           not null
#  status              :integer          default("sent")
#  subject             :string           not null
#  template            :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  provider_message_id :string
#
# Indexes
#
#  index_email_logs_on_status  (status)
#
require "rails_helper"

RSpec.describe EmailLog do
  let(:email_log) { build(:email_log, recipient: "test@example.com", subject: "Test", template: "test_template") }

  describe "validations" do
    it { is_expected.to validate_presence_of(:recipient) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:template) }

    it "validates email format" do
      email_log.recipient = "invalid-email"
      expect(email_log).not_to be_valid
      expect(email_log.errors[:recipient]).to be_present
    end

    it "allows valid email format" do
      email_log.recipient = "valid@example.com"
      expect(email_log).to be_valid
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(sent: 0, failed: 1, sandbox: 2) }
  end

  describe "attributes" do
    it "stores payload_json" do
      email_log.payload_json = '{"key": "value"}'
      email_log.save
      expect(email_log.reload.payload_json).to eq('{"key": "value"}')
    end

    it "stores provider_message_id" do
      email_log.provider_message_id = "msg-12345"
      email_log.save
      expect(email_log.reload.provider_message_id).to eq("msg-12345")
    end
  end
end
