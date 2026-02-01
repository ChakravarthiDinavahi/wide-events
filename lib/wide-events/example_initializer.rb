# frozen_string_literal: true

# Example initializer for wide-events
# Copy this to config/initializers/wide_events.rb in your Rails app

# WideEvents.configure do |config|
#   # Sampling rate for normal requests (0.05 = 5%)
#   config.sample_rate = 0.05
#
#   # Always sample errors (default: true)
#   config.always_sample_errors = true
#
#   # Always sample slow requests (default: true)
#   config.always_sample_slow_requests = true
#   config.slow_request_threshold_ms = 2000 # 2 seconds
#
#   # Always sample specific users (VIPs, test accounts)
#   config.always_sample_users = ['user_123', 'user_456']
#
#   # Always sample specific paths (debugging rollouts)
#   config.always_sample_paths = [/\/api\/v1\/checkout/, /\/admin/]
#
#   # Service metadata
#   config.service_name = ENV['SERVICE_NAME'] || 'my-app'
#   config.service_version = ENV['SERVICE_VERSION'] || '1.0.0'
#   config.deployment_id = ENV['DEPLOYMENT_ID']
#   config.region = ENV['REGION']
#
#   # Custom logger (defaults to Rails.logger)
#   # config.logger = MyCustomLogger.new
#
#   # Enable/disable wide events
#   config.enabled = Rails.env.production? || Rails.env.staging?
# end
