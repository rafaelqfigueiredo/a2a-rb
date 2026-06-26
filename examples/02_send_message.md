# Sending a message

`Client#send_message` covers the `SendMessage` JSON-RPC method and the
equivalent `POST /message:send` HTTP+JSON path. The server responds with
either a `Task` or a `Message`.

## Basic text message

```ruby
require "a2a"

client = A2A::Client.new(
  protocol: A2A::Protocol::HttpJson.new(url: "https://agent.example.com")
)

message = A2A::Message.new(
  id: SecureRandom.uuid,
  role: A2A::Role::USER,
  parts: [A2A::Part::Text.new(text: "Summarise the attached document.")]
)

result = client.send_message(message)

case result
when A2A::Task
  puts "Task #{result.id} is #{result.status.state}"
when A2A::Message
  puts result.parts.first.text
end
```

## Multi-part message (text + file)

```ruby
message = A2A::Message.new(
  id: SecureRandom.uuid,
  role: A2A::Role::USER,
  parts: [
    A2A::Part::Text.new(text: "What does this chart show?"),
    A2A::Part::File.new(
      url: "https://storage.example.com/chart.png",
      media_type: "image/png",
      filename: "chart.png"
    )
  ]
)

result = client.send_message(message)
```

## Structured data part

Use `Part::Data` when the content is machine-readable JSON rather than prose.

```ruby
message = A2A::Message.new(
  id: SecureRandom.uuid,
  role: A2A::Role::USER,
  parts: [
    A2A::Part::Data.new(data: { "invoice_id" => "INV-001", "amount" => 99.99 })
  ]
)
```

## Request configuration

```ruby
config = A2A::Operation::SendMessage::Configuration.new(
  accepted_output_modes: ["text/plain"],
  history_length: 10,
  return_immediately: true  # respond with SUBMITTED instead of waiting
)

result = client.send_message(message, configuration: config)
```

## Passing metadata and tenant

Both `metadata` and `tenant` are forwarded as top-level request fields per
the A2A spec.

```ruby
result = client.send_message(
  message,
  metadata: { "trace_id" => "abc123" },
  tenant: "acme-corp"
)
```

## Error handling

```ruby
begin
  result = client.send_message(message)
rescue A2A::AuthenticationError
  # 401 — credentials missing or invalid
rescue A2A::TaskNotFoundError
  # -32001 — referenced task no longer exists
rescue A2A::ContentTypeNotSupportedError
  # -32005 — agent cannot handle the given input mode
rescue A2A::Error => e
  puts "A2A error #{e.code}: #{e.message}"
end
```
