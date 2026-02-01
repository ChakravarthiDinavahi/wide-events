# frozen_string_literal: true

require "securerandom"

module WideEvents
  # Builds a comprehensive wide event throughout the request lifecycle
  class EventBuilder
    attr_reader :event

    def initialize(request_context = {})
      @event = {
        timestamp: current_time.iso8601(3),
        service: WideEvents.configuration.service_name,
        version: WideEvents.configuration.service_version,
        deployment_id: WideEvents.configuration.deployment_id,
        region: WideEvents.configuration.region,
        node_env: rails_env,
        **request_context
      }
    end

    def add_request_info(request)
      @event.merge!(
        request_id: request.headers["X-Request-ID"] || SecureRandom.uuid,
        method: request.method,
        path: request.path,
        query_string: request.query_string.presence,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        referer: request.referer
      )
      self
    end

    def add_user_context(user)
      return self unless user

      @event[:user] = {
        id: user.respond_to?(:id) ? user.id : nil,
        email: user.respond_to?(:email) ? user.email : nil,
        subscription: user.respond_to?(:subscription) ? user.subscription : nil,
        account_age_days: user.respond_to?(:created_at) ? days_since(user.created_at) : nil,
        lifetime_value_cents: user.respond_to?(:lifetime_value_cents) ? user.lifetime_value_cents : nil
      }
      self
    end

    def add_business_context(context)
      @event.merge!(context)
      self
    end

    def add_error(error)
      @event[:error] = {
        type: error.class.name,
        message: error.message,
        code: error.respond_to?(:code) ? error.code : nil,
        retriable: error.respond_to?(:retriable?) ? error.retriable? : false,
        backtrace: error.backtrace&.first(5)
      }
      @event[:outcome] = "error"
      self
    end

    def add_response_info(status_code, duration_ms)
      @event[:status_code] = status_code
      @event[:duration_ms] = duration_ms
      @event[:outcome] ||= (status_code >= 400 ? "error" : "success")
      self
    end

    def add_metadata(key, value)
      @event[key] = value
      self
    end

    def to_h
      @event.dup
    end

    private

    def current_time
      defined?(Time.current) ? Time.current : Time.now
    end

    def rails_env
      defined?(Rails) ? Rails.env : ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
    end

    def days_since(date)
      return nil unless date

      now = current_time
      date_time = date.respond_to?(:to_time) ? date.to_time : date
      ((now - date_time) / 86_400).to_i
    end
  end
end
