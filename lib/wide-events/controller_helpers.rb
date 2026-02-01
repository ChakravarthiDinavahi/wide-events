# frozen_string_literal: true

module WideEvents
  # Controller helpers to enrich events with business context
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      before_action :setup_wide_event
    end

    private

    def setup_wide_event
      @wide_event_builder = request.env["wide_events.builder"]
    end

    # Add business context to the wide event
    # Usage: add_wide_event_context(cart: { id: cart.id, item_count: cart.items.count })
    def add_wide_event_context(context)
      @wide_event_builder&.add_business_context(context)
    end

    # Add custom metadata to the wide event
    # Usage: add_wide_event_metadata(:feature_flag, "new_checkout_flow")
    def add_wide_event_metadata(key, value)
      @wide_event_builder&.add_metadata(key, value)
    end

    # Measure and add timing for a specific operation
    # Usage: measure_wide_event(:payment_latency_ms) { process_payment }
    def measure_wide_event(key)
      start_time = current_time
      result = yield
      duration_ms = ((current_time - start_time) * 1000).round
      @wide_event_builder&.add_metadata(key, duration_ms)
      result
    end

    def current_time
      defined?(Time.current) ? Time.current : Time.now
    end
  end
end
