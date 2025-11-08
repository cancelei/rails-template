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
class EmailLog < ApplicationRecord
  enum :status, { sent: 0, failed: 1, sandbox: 2 }

  validates :recipient, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :template, presence: true

  # Alias methods for view compatibility
  def recipient_email
    recipient
  end

  def email_type
    template
  end

  def sent_at
    created_at
  end
end
