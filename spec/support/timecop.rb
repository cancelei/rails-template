require "timecop"

RSpec.configure do |config|
  config.after do
    # Always reset time after each test to prevent test pollution
    Timecop.return
  end
end
