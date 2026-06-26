# Streaming

`Client#send_streaming_message` and `Client#subscribe_to_task` both return
a stream of `Streaming::Response` events over SSE. The stream terminates
automatically when the gem detects a terminal state.

## Streaming a message with a block

```ruby
require "a2a"

client = A2A::Client.new(
  protocol: A2A::Protocol::HttpJson.new(url: "https://agent.example.com")
)

message = A2A::Message.new(
  id: SecureRandom.uuid,
  role: A2A::Role::USER,
  parts: [A2A::Part::Text.new(text: "Write me a haiku about Ruby.")]
)

client.send_streaming_message(message) do |event|
  case event.type
  when :status_update
    puts "[#{event.payload.status.state}]"
  when :artifact_update
    artifact = event.payload.artifact
    artifact.parts.each do |part|
      print part.text if part.is_a?(A2A::Part::Text)
    end
    puts if event.payload.last_chunk
  when :task
    puts "Task snapshot: #{event.payload.status.state}"
  when :message
    puts "Agent replied: #{event.payload.parts.first.text}"
  end
end
```

## Collecting artifacts from a chunked stream

Agents may emit an artifact across multiple `ArtifactUpdateEvent`s. Accumulate
parts until `last_chunk` is true.

```ruby
buffer = []

client.send_streaming_message(message) do |event|
  next unless event.artifact_update?

  ev = event.payload
  buffer.concat(ev.artifact.parts)

  if ev.last_chunk
    puts "Full artifact: #{buffer.map(&:text).join}"
    buffer.clear
  end
end
```

## Subscription object (no block)

Calling without a block returns a `Streaming::Subscription`, which is
`Enumerable`. This is useful when you want to drive iteration yourself
or pass the subscription to another object.

```ruby
sub = client.send_streaming_message(message)

sub.each do |event|
  break if event.status_update? && event.payload.final?
  process(event)
end
```

## Subscribe to an existing task

```ruby
client.subscribe_to_task("task-abc123") do |event|
  puts event.type
end
```

## Writing SSE frames from a server

`Streaming::SSEWriter` is the server-side counterpart to the built-in
`SseParser`. Use it in any Rack-compatible streaming response.

```ruby
require "a2a"

# Inside a Rails or Rack streaming block:
response.stream.write(
  A2A::Streaming::SSEWriter.encode(
    A2A::Streaming::Response.new(
      :status_update,
      A2A::Streaming::StatusUpdateEvent.new(
        task_id: "t1",
        context_id: "ctx-1",
        status: A2A::Task::Status.new(state: A2A::Task::State::WORKING)
      )
    ),
    id: request_id
  )
)

# On error:
response.stream.write(
  A2A::Streaming::SSEWriter.encode_error(
    A2A::InternalError.new("something went wrong", code: -32603),
    id: request_id
  )
)
```

Each call produces a complete SSE frame: `data: {...}\n\n`.
