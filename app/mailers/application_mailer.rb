class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.app.mail_from
  layout "mailer"
end
