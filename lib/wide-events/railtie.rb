# frozen_string_literal: true

module WideEvents
  # Rails integration
  class Railtie < Rails::Railtie
    initializer "wide_events.middleware" do |app|
      app.middleware.use WideEvents::Middleware
    end

    config.after_initialize do
      WideEvents.configure do |config|
        config.logger ||= Rails.logger
      end
    end
  end
end
