# Override default test task to run RSpec
require "rspec/core/rake_task"

Rake::Task[:test].clear if Rake::Task.task_defined?(:test)

desc "Run all RSpec tests with coverage"
task test: :environment do
  # Run RSpec tests
  sh "bundle exec rspec"
end

namespace :test do
  desc "Run all RSpec tests including system tests"
  task all: :environment do
    sh "bundle exec rspec"
  end
end
