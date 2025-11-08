# Staging configuration is identical to production, with some overrides
# for hostname, etc.

require_relative "production"

Rails.application.configure do
  # Override production storage to use staging bucket
  config.active_storage.service = :idrive_staging

  config.action_mailer.default_url_options = {
    host: "staging.example.com",
    protocol: "https"
  }
  config.action_mailer.asset_host = "https://staging.example.com"

  # Override production SMTP settings with Emailit for staging
  config.action_mailer.smtp_settings = {
    address: "smtp.emailit.com",
    port: ENV.fetch("SMTP_PORT", 587),
    enable_starttls_auto: true,
    user_name: ENV.fetch("EMAILIT_USERNAME"),
    password: ENV.fetch("EMAILIT_API_KEY"),
    authentication: :plain,
    domain: "staging.example.com"
  }
end
