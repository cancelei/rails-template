require_relative "../lib/audit_log_log_formatter"
require_relative "boot"
require_relative "../app/middleware/http_basic_auth"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Guide
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Wellington"
    # config.eager_load_paths << Rails.root.join("extras")

    # load config/app.yml into Rails.application.config.app.*
    config.app = config_for(:app)

    # pull the secret_key_base from our app config
    config.secret_key_base = config.app.secret_key_base

    config.middleware.insert_before Rack::Sendfile, HttpBasicAuth
    config.action_dispatch.default_headers["Permissions-Policy"] = "interest-cohort=()"

    # Configure the encryption key for ActiveRecord encrypted attributes with values from our app config,
    # as Rails only automatically picks them up if they're sourced from `config/credentials.yml.enc`
    config.active_record.encryption.primary_key = Rails.application.config.app.active_record_encryption_primary_key
    config.active_record.encryption.deterministic_key = Rails.application.config.app.active_record_encryption_deterministic_key
    config.active_record.encryption.key_derivation_salt = Rails.application.config.app.active_record_encryption_key_derivation_salt

    config.action_dispatch.default_headers["X-Frame-Options"] = "DENY"

    # gzip Rails responses to help browsers on slow network connections.
    config.middleware.use Rack::Deflater

    config.audit_logger = if ENV["RAILS_LOG_TO_STDOUT"].present?
                            Logger.new($stdout, formatter: AuditLogLogFormatter.new)
                          else
                            Logger.new("log/audit.log", formatter: AuditLogLogFormatter.new)
                          end
  end
end
