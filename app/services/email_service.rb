class EmailService
  def self.send_email(to, template, data)
    # In a real implementation, this would call EMAILIT API
    # For now, log the email
    EmailLog.create!(
      recipient: to,
      subject: data[:subject],
      template:,
      payload_json: data.to_json,
      status: ENV["EMAILIT_SANDBOX"] ? :sandbox : :sent
    )
  end
end
