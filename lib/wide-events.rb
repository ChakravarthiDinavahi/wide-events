# frozen_string_literal: true

require_relative "wide-events/version"
require_relative "wide-events/event_builder"
require_relative "wide-events/middleware"
require_relative "wide-events/sampler"
require_relative "wide-events/controller_helpers"
require_relative "wide-events/railtie" if defined?(Rails)

module WideEvents
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end
  end

  class Configuration
    attr_accessor :logger
    attr_accessor :sample_rate
    attr_accessor :always_sample_errors
    attr_accessor :always_sample_slow_requests
    attr_accessor :slow_request_threshold_ms
    attr_accessor :always_sample_users
    attr_accessor :always_sample_paths
    attr_accessor :service_name
    attr_accessor :service_version
    attr_accessor :deployment_id
    attr_accessor :region
    attr_accessor :enabled

    def initialize
      @logger = nil
      @sample_rate = 0.05 # 5% default
      @always_sample_errors = true
      @always_sample_slow_requests = true
      @slow_request_threshold_ms = 2000
      @always_sample_users = []
      @always_sample_paths = []
      @service_name = ENV["SERVICE_NAME"] || "rails-app"
      @service_version = ENV["SERVICE_VERSION"] || "unknown"
      @deployment_id = ENV["DEPLOYMENT_ID"] || nil
      @region = ENV["REGION"] || nil
      @enabled = true
    end
  end
end
