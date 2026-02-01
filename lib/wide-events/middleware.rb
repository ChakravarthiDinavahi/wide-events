# frozen_string_literal: true

require "json"

module WideEvents
  # Rails middleware to capture wide events throughout request lifecycle
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      start_time = current_time

      # Initialize the wide event with request context
      event_builder = EventBuilder.new
      event_builder.add_request_info(request)

      # Make the event builder accessible to controllers
      env["wide_events.builder"] = event_builder

      # Add user context if available
      if defined?(Current) && Current.respond_to?(:user) && Current.user
        event_builder.add_user_context(Current.user)
      end

      # Process the request
      status, headers, response = @app.call(env)

      # Calculate duration
      duration_ms = ((current_time - start_time) * 1000).round

      # Add response info
      event_builder.add_response_info(status, duration_ms)

      # Get the final event
      event = event_builder.to_h

      # Tail sampling: decide whether to log after request completes
      if Sampler.should_sample?(event)
        log_event(event)
      end

      [status, headers, response]
    rescue StandardError => e
      # Capture errors
      duration_ms = ((current_time - start_time) * 1000).round
      event_builder.add_error(e)
      event_builder.add_response_info(500, duration_ms)

      event = event_builder.to_h

      # Always log errors (sampler will also catch this, but be explicit)
      log_event(event)

      raise
    end

    private

    def current_time
      defined?(Time.current) ? Time.current : Time.now
    end

    def log_event(event)
      logger = WideEvents.configuration.logger
      logger ||= defined?(Rails) ? Rails.logger : Logger.new($stdout)
      logger.info(event.to_json)
    end
  end
end
