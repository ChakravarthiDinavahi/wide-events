# Wide Events

A Rails gem that implements the [wide events pattern](https://loggingsucks.com) for comprehensive, contextual, and queryable logging.

## What are Wide Events?

Wide events are a logging best practice where you capture **all context in a single comprehensive event per request**, rather than scattering information across multiple log lines. This makes debugging and analytics dramatically easier.

Instead of searching through logs hoping to find relevant information, you query structured data with all the context you need.

## Features

- 🎯 **One event per request** with all context attached
- 📊 **High-cardinality, high-dimensionality** data capture
- 🎲 **Tail sampling** to keep costs under control
- 🔍 **Structured JSON logging** ready for analytics
- 🚀 **Zero-configuration** Rails integration
- 🎛️ **Flexible configuration** for your needs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wide-events'
```

And then execute:

```bash
$ bundle install
```

## Quick Start

The gem works out of the box with sensible defaults. Just add it to your Gemfile and start using it!

### Basic Usage

In your controllers, enrich events with business context:

```ruby
class CheckoutController < ApplicationController
  include WideEvents::ControllerHelpers

  def create
    # Add business context as you process
    cart = current_user.cart
    add_wide_event_context(
      cart: {
        id: cart.id,
        item_count: cart.items.count,
        total_cents: cart.total,
        coupon_applied: cart.coupon&.code
      }
    )

    # Measure specific operations
    payment = measure_wide_event(:payment_latency_ms) do
      process_payment(cart, current_user)
    end

    # Add payment context
    add_wide_event_context(
      payment: {
        method: payment.method,
        provider: payment.provider,
        attempt: payment.attempt_number
      }
    )

    # If payment fails, error is automatically captured
    if payment.error
      add_wide_event_context(
        error: {
          type: 'PaymentError',
          code: payment.error.code,
          stripe_decline_code: payment.error.decline_code
        }
      )
    end

    render json: { order_id: payment.order_id }
  end
end
```

## Configuration

Configure wide events in an initializer:

```ruby
# config/initializers/wide_events.rb
WideEvents.configure do |config|
  # Sampling rate for normal requests (0.05 = 5%)
  config.sample_rate = 0.05

  # Always sample errors (default: true)
  config.always_sample_errors = true

  # Always sample slow requests (default: true)
  config.always_sample_slow_requests = true
  config.slow_request_threshold_ms = 2000 # 2 seconds

  # Always sample specific users (VIPs, test accounts)
  config.always_sample_users = ['user_123', 'user_456']

  # Always sample specific paths (debugging rollouts)
  config.always_sample_paths = [/\/api\/v1\/checkout/, /\/admin/]

  # Service metadata
  config.service_name = ENV['SERVICE_NAME'] || 'my-app'
  config.service_version = ENV['SERVICE_VERSION'] || '1.0.0'
  config.deployment_id = ENV['DEPLOYMENT_ID']
  config.region = ENV['REGION']

  # Custom logger (defaults to Rails.logger)
  # config.logger = MyCustomLogger.new

  # Enable/disable wide events
  config.enabled = Rails.env.production? || Rails.env.staging?
end
```

## Tail Sampling

Tail sampling means making the sampling decision **after** the request completes, based on its outcome. This ensures you never lose important events:

1. **Always keep errors** - 100% of 500s, exceptions, and failures
2. **Always keep slow requests** - Anything above your p99 latency threshold
3. **Always keep specific users** - VIP customers, internal testing accounts
4. **Always keep specific paths** - Feature flags, debugging rollouts
5. **Randomly sample the rest** - Happy, fast requests at your configured rate

## What Gets Logged

Each wide event includes:

### Request Context
- `request_id` - Unique request identifier
- `method` - HTTP method (GET, POST, etc.)
- `path` - Request path
- `query_string` - Query parameters
- `ip` - Client IP address
- `user_agent` - User agent string
- `referer` - Referer header

### Response Context
- `status_code` - HTTP status code
- `duration_ms` - Request duration in milliseconds
- `outcome` - "success" or "error"

### Service Context
- `service` - Service name
- `version` - Service version
- `deployment_id` - Deployment identifier
- `region` - Region/availability zone
- `node_env` - Rails environment

### User Context (if available)
- `user.id` - User ID
- `user.email` - User email
- `user.subscription` - Subscription tier
- `user.account_age_days` - Account age
- `user.lifetime_value_cents` - Customer lifetime value

### Error Context (if error occurred)
- `error.type` - Error class name
- `error.message` - Error message
- `error.code` - Error code (if available)
- `error.retriable` - Whether error is retriable
- `error.backtrace` - First 5 lines of backtrace

### Business Context (added by you)
Any context you add via `add_wide_event_context` or `add_wide_event_metadata`

## Example Event

```json
{
  "timestamp": "2024-12-20T03:14:23.156Z",
  "request_id": "req_8f7a2b3c",
  "method": "POST",
  "path": "/api/v1/checkout",
  "ip": "192.168.1.42",
  "user_agent": "Mozilla/5.0",
  "service": "api-gateway",
  "version": "2.4.1",
  "deployment_id": "deploy_abc123",
  "region": "us-east-1",
  "node_env": "production",
  "user": {
    "id": "user_abc123",
    "email": "user@example.com",
    "subscription": "premium",
    "account_age_days": 45,
    "lifetime_value_cents": 50000
  },
  "cart": {
    "id": "cart_xyz789",
    "item_count": 3,
    "total_cents": 9999,
    "coupon_applied": "SAVE10"
  },
  "payment": {
    "method": "card",
    "provider": "stripe",
    "latency_ms": 234,
    "attempt": 1
  },
  "status_code": 200,
  "duration_ms": 1247,
  "outcome": "success"
}
```

## Querying Events

With wide events, you're not searching text anymore—you're querying structured data. Use your log aggregation tool (Datadog, New Relic, CloudWatch, etc.) to run queries like:

```
Show me all checkout failures for premium users in the last hour 
where the new checkout flow was enabled, grouped by error code
```

Or:

```
Find all requests where payment_latency_ms > 1000 and status_code = 200
```

## Controller Helpers

The gem provides helper methods in your controllers:

### `add_wide_event_context(context)`
Add business context to the event:

```ruby
add_wide_event_context(
  cart: { id: cart.id, total: cart.total },
  feature_flags: { new_checkout: true }
)
```

### `add_wide_event_metadata(key, value)`
Add a single metadata field:

```ruby
add_wide_event_metadata(:experiment_variant, "A")
```

### `measure_wide_event(key)`
Measure and record the duration of an operation:

```ruby
result = measure_wide_event(:database_query_ms) do
  User.where(org_id: org_id).to_a
end
```

## Advanced Usage

### Custom User Context

If your user model doesn't match the default attributes, you can customize user context extraction:

```ruby
# In an initializer or concern
module Current
  attr_accessor :user
end

# In your authentication code
Current.user = user # WideEvents will automatically capture user context
```

### Manual Event Building

For background jobs or non-HTTP contexts:

```ruby
event_builder = WideEvents::EventBuilder.new
event_builder.add_user_context(user)
event_builder.add_business_context(job: { id: job.id, type: job.class.name })
event_builder.add_response_info(200, 1500)

event = event_builder.to_h
if WideEvents::Sampler.should_sample?(event)
  Rails.logger.info(event.to_json)
end
```

## Best Practices

1. **Add context early and often** - Don't wait until the end of the request
2. **Include business metrics** - Cart totals, item counts, feature flags
3. **Measure important operations** - Database queries, external API calls
4. **Use meaningful keys** - `payment_latency_ms` not `latency1`
5. **Keep sampling rates low** - 1-5% for normal traffic is usually sufficient
6. **Always sample errors** - Never drop error events

## Performance

Wide events are designed to be lightweight:

- Event building happens in memory
- Sampling decision is made after request completes
- Only sampled events are logged
- No blocking I/O during request processing

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/username/wide-events.git.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## References

- [Logging Sucks - Wide Events Explained](https://loggingsucks.com)
- [OpenTelemetry](https://opentelemetry.io/)
- [Structured Logging Best Practices](https://www.honeycomb.io/blog/structure-your-logs)
