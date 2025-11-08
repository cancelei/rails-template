require "webmock/rspec"

RSpec.configure do |config|
  config.before do
    # Disable real HTTP requests in tests (allow localhost for test server)
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
