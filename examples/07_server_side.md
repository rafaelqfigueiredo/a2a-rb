# Server-side request handling

This example shows how to handle incoming A2A calls on the server. The gem
provides three protocol-level building blocks — `JSONRPCEnvelope`,
`SendMessageRequest`, and `SSEWriter` — that a framework layer (e.g.
`a2a-rails`) sits on top of.

## Parsing an incoming SendMessage request

`Operation::SendMessageRequest.from_h` deserialises the params hash from
either a JSON-RPC envelope or an HTTP+JSON request body into typed objects.

```ruby
require "a2a"

# Incoming JSON-RPC request body (already parsed from JSON):
raw = {
  "jsonrpc" => "2.0",
  "id"      => "req-1",
  "method"  => "SendMessage",
  "params"  => {
    "message" => {
      "messageId" => "m1",
      "role"      => A2A::Role::USER,
      "parts"     => [{ "text" => "Summarise this." }]
    },
    "configuration" => { "historyLength" => 5 },
    "metadata"      => { "trace_id" => "abc" },
    "tenant"        => "acme"
  }
}

id, method, params = A2A::JSONRPCEnvelope.parse_request(raw)
# id     => "req-1"
# method => "SendMessage"

req = A2A::Operation::SendMessageRequest.from_h(params)

req.message.parts.first.text        # "Summarise this."
req.configuration.history_length    # 5
req.metadata                        # { "trace_id" => "abc" }
req.tenant                          # "acme"
```

## Building JSON-RPC response envelopes

```ruby
task = A2A::Task.new(
  id: "t1",
  status: A2A::Task::Status.new(state: A2A::Task::State::SUBMITTED)
)

# Success response — result is the A2A payload hash
response = A2A::JSONRPCEnvelope.success(
  id: "req-1",
  result: { "task" => task.to_h }
)
JSON.generate(response)
# {"jsonrpc":"2.0","id":"req-1","result":{"task":{...}}}

# Error response — code is taken from the A2A::Error subclass
error = A2A::TaskNotFoundError.new("task t1 not found", code: -32001)
response = A2A::JSONRPCEnvelope.error(id: "req-1", error: error)
# {"jsonrpc":"2.0","id":"req-1","error":{"code":-32001,"message":"task t1 not found"}}
```

## Minimal Rack JSON-RPC handler

Putting it together: a Rack app that handles `SendMessage` and returns a task.

```ruby
require "a2a"
require "json"

class A2AHandler
  METHOD_MAP = {
    "SendMessage" => :handle_send_message
  }.freeze

  def call(env)
    body = JSON.parse(env["rack.input"].read)
    id, method, params = A2A::JSONRPCEnvelope.parse_request(body)

    handler = METHOD_MAP[method]
    raise A2A::MethodNotFoundError.new("unknown method: #{method}", code: -32601) unless handler

    result = public_send(handler, params)
    json(200, A2A::JSONRPCEnvelope.success(id: id, result: result))
  rescue A2A::Error => e
    json(200, A2A::JSONRPCEnvelope.error(id: id, error: e))
  rescue JSON::ParserError => e
    json(400, A2A::JSONRPCEnvelope.error(id: nil, error: A2A::JSONParseError.new(e.message, code: -32700)))
  end

  def handle_send_message(params)
    req = A2A::Operation::SendMessageRequest.from_h(params)

    # Build and persist a task (storage is your framework's concern)
    task = A2A::Task.new(
      id: SecureRandom.uuid,
      status: A2A::Task::Status.new(state: A2A::Task::State::SUBMITTED)
    )

    { "task" => task.to_h }
  end

  private

  def json(status, body)
    [status, { "Content-Type" => "application/json" }, [JSON.generate(body)]]
  end
end
```

## Streaming response with SSEWriter

For `SendStreamingMessage`, write SSE frames one at a time as the agent
produces output.

```ruby
# Inside a Rails ActionController::Live action or any Rack streaming block:

response.headers["Content-Type"] = "text/event-stream"
response.headers["Cache-Control"] = "no-cache"

request_id = "req-1"
task_id    = "t1"
context_id = "ctx-1"

# 1. Emit WORKING status
response.stream.write(
  A2A::Streaming::SSEWriter.encode(
    A2A::Streaming::Response.new(
      :status_update,
      A2A::Streaming::StatusUpdateEvent.new(
        task_id: task_id, context_id: context_id,
        status: A2A::Task::Status.new(state: A2A::Task::State::WORKING)
      )
    ),
    id: request_id
  )
)

# 2. Emit artifact chunk
response.stream.write(
  A2A::Streaming::SSEWriter.encode(
    A2A::Streaming::Response.new(
      :artifact_update,
      A2A::Streaming::ArtifactUpdateEvent.new(
        task_id: task_id, context_id: context_id,
        artifact: A2A::Artifact.new(
          id: "a1",
          parts: [A2A::Part::Text.new(text: "Here is your answer...")]
        ),
        append: false,
        last_chunk: true
      )
    ),
    id: request_id
  )
)

# 3. Emit final COMPLETED status
response.stream.write(
  A2A::Streaming::SSEWriter.encode(
    A2A::Streaming::Response.new(
      :status_update,
      A2A::Streaming::StatusUpdateEvent.new(
        task_id: task_id, context_id: context_id,
        status: A2A::Task::Status.new(state: A2A::Task::State::COMPLETED),
        final: true
      )
    ),
    id: request_id
  )
)
```

The client's `Streaming::Subscription` will stop iterating once it sees a
`final: true` status update or a terminal task state.
