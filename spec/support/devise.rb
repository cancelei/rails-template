RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers

  # Ensure Warden is set up for tests
  config.before(:suite) do
    Warden.test_mode!
  end

  config.after do
    Warden.test_reset!
  end
end
