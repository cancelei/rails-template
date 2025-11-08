require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Hide sensitive data in recorded cassettes
  config.filter_sensitive_data("<OPENWEATHER_API_KEY>") { ENV.fetch("OPENWEATHER_API_KEY", nil) }

  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body]
  }

  # Ignore localhost requests
  config.ignore_localhost = true
end
