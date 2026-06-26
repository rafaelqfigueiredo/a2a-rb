# Push notifications

Push notifications let an agent deliver task updates to a webhook rather than
requiring the client to poll or hold a streaming connection open. The gem
provides both sides: a `Dispatcher` for sending and a `Receiver` Rack
middleware for receiving.

## Register a push notification config

```ruby
require "a2a"

client = A2A::Client.new(
  protocol: A2A::Protocol::HttpJson.new(url: "https://agent.example.com")
)

config = A2A::PushNotification::Config.new(
  url: "https://myapp.example.com/a2a/webhook",
  id: "cfg-001",
  token: "shared-secret",
  task_id: "task-abc123",
  authentication: A2A::PushNotification::AuthenticationInfo.new(
    scheme: "Bearer",
    credentials: "my-webhook-token"
  )
)

saved = client.create_task_push_notification_config(config)
puts saved.id
```

## Fetch and list configs

```ruby
# Fetch a specific config
cfg = client.get_task_push_notification_config(task_id: "task-abc123", id: "cfg-001")

# List all configs for a task
response = client.list_task_push_notification_configs(task_id: "task-abc123")
response.configs.each { |c| puts c.url }

# Delete a config
client.delete_task_push_notification_config(task_id: "task-abc123", id: "cfg-001")
```

## Receive push notifications (Rack middleware)

`PushNotification::Receiver` is a Rack middleware. Mount it in front of your
application to intercept incoming push events.

```ruby
# config.ru (pure Rack)
require "a2a"

handler = lambda do |event|
  case event.type
  when :status_update
    puts "Task #{event.payload.task_id} → #{event.payload.status.state}"
  when :artifact_update
    puts "New artifact for #{event.payload.task_id}"
  end
end

use A2A::PushNotification::Receiver,
    path: "/a2a/webhook",
    scheme: "Bearer",
    credentials: "my-webhook-token",
    &handler

run MyApp
```

In Rails, add it to `config/application.rb`:

```ruby
config.middleware.use A2A::PushNotification::Receiver,
                      path: "/a2a/webhook",
                      credentials: Rails.application.credentials.a2a_webhook_token do |event|
  A2AWebhookJob.perform_later(event.to_h.to_json)
end
```

The middleware validates the `Authorization: Bearer <token>` header when
`credentials:` is set and returns 401 otherwise. Unknown or malformed JSON
bodies return 400.

## Dispatch push notifications (server side)

Use `Dispatcher` when your agent server needs to POST events to a registered
webhook URL.

```ruby
dispatcher = A2A::PushNotification::Dispatcher.new

config = A2A::PushNotification::Config.new(
  url: "https://client.example.com/webhook",
  authentication: A2A::PushNotification::AuthenticationInfo.new(
    scheme: "Bearer",
    credentials: "client-token"
  )
)

event = A2A::Streaming::Response.new(
  :status_update,
  A2A::Streaming::StatusUpdateEvent.new(
    task_id: "t1",
    context_id: "ctx-1",
    status: A2A::Task::Status.new(state: A2A::Task::State::COMPLETED)
  )
)

dispatcher.dispatch(config, event)
# POST https://client.example.com/webhook
# Authorization: Bearer client-token
# Content-Type: application/json
```

`dispatch` raises `A2A::TransportError` on non-2xx responses.
