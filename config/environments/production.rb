require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  #
  # You should never use this because it just blindly sets headers without any actual
  # checks; instead, whatever is handling the SSL-termination should be setting the
  # appropriate headers to indicate that the request was actually SSL-terminated.
  config.assume_ssl = false

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  #
  # On by default, though can be disabled by setting RAILS_FORCE_SSL=false (and only "false")
  config.force_ssl = ENV.fetch("RAILS_FORCE_SSL", "true").downcase != "false"

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger   = ActiveSupport::TaggedLogging.logger($stdout)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", ENV.fetch("LOG_LEVEL", "info"))

  # Prevent health checks from clogging up the logs.
  # config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store
  if ENV.fetch("RAILS_CACHE_REDIS_URL", nil)
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("RAILS_CACHE_REDIS_URL"),
      ##
      # Configuring a connection pool for Redis as Rails cache is documented in:
      #
      # * https://edgeguides.rubyonrails.org/caching_with_rails.html#connection-pool-options
      #
      # but some more details are available in:
      #
      # * https://github.com/rails/rails/blob/a5d1628c79ab89dfae57ec1e1aeca467e29de188/activesupport/lib/active_support/cache.rb#L168-L173
      # * https://github.com/rails/rails/blob/9b4aef4be3dc58eb08f694387857b52be8050954/activesupport/lib/active_support/cache/redis_cache_store.rb#L185-L192
      #
      pool_size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)), # number of connections **per puma process**
      pool_timeout: 5 # num seconds to wait for a connection
    }
  end

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = true

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = {
    host: "www.example.com",
    protocol: "https"
  }

  config.action_mailer.asset_host = "https://www.example.com"

  # Specify outgoing SMTP server.
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_HOSTNAME"),
    port: ENV.fetch("SMTP_PORT", 587),
    enable_starttls_auto: true,
    user_name: ENV.fetch("SMTP_USERNAME"),
    password: ENV.fetch("SMTP_PASSWORD"),
    authentication: "login",
    domain: "www.example.com"
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
