# frozen_string_literal: true

module WideEvents
  # Implements tail sampling logic: sample after request completes based on outcome
  class Sampler
    def self.should_sample?(event)
      config = WideEvents.configuration
      return false unless config.enabled

      # Always keep errors
      return true if config.always_sample_errors && error?(event)

      # Always keep slow requests
      return true if config.always_sample_slow_requests && slow_request?(event)

      # Always keep specific users
      return true if always_sample_user?(event)

      # Always keep specific paths
      return true if always_sample_path?(event)

      # Randomly sample the rest
      rand < config.sample_rate
    end

    def self.error?(event)
      event[:status_code]&.>= 400 || event[:error].present? || event[:outcome] == "error"
    end

    def self.slow_request?(event)
      return false unless WideEvents.configuration.always_sample_slow_requests

      duration = event[:duration_ms]
      return false unless duration

      duration > WideEvents.configuration.slow_request_threshold_ms
    end

    def self.always_sample_user?(event)
      config = WideEvents.configuration
      return false if config.always_sample_users.empty?

      user_id = event.dig(:user, :id)
      return false unless user_id

      config.always_sample_users.include?(user_id.to_s) || config.always_sample_users.include?(user_id)
    end

    def self.always_sample_path?(event)
      config = WideEvents.configuration
      return false if config.always_sample_paths.empty?

      path = event[:path]
      return false unless path

      config.always_sample_paths.any? { |pattern| path.match?(pattern) }
    end
  end
end
