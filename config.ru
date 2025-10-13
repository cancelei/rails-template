# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

use Rack::CanonicalHost, ENV["CANONICAL_HOSTNAME"] if ENV["CANONICAL_HOSTNAME"].present?
run Rails.application
Rails.application.load_server
