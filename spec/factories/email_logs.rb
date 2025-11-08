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
FactoryBot.define do
  factory :email_log do
    sequence(:recipient) { |n| "user#{n}@example.com" }
    subject { "Test Email Subject" }
    template { "test_template" }
    payload_json { "MyText" }
    provider_message_id { "test-message-id" }
    status { 0 }
  end
end
