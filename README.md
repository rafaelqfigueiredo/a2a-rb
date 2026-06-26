# a2a-rb

Ruby implementation of the [A2A protocol v1.0](https://a2a-protocol.org/latest/specification) — an open standard for agent-to-agent communication.

The gem is a **data-model and serialisation library**: it models every message
type from the A2A spec, provides a full client for calling remote agents, and
includes protocol-level primitives for building server-side handlers. No HTTP
server is bundled — mount it behind Rails, Sinatra, or any Rack application.

- Ruby 3.4+
- No runtime dependencies
- Both JSON-RPC 2.0 and HTTP+JSON bindings

## Installation

```ruby
# Gemfile
gem "a2a-rb"
```

```bash
bundle install
```

## Quick start

```ruby
require "a2a"

# 1. Discover an agent
card = A2A::Discovery.fetch("https://agent.example.com")

# 2. Build a client (negotiates the best available protocol binding)
client = A2A::Client.from_agent_card(card)

# 3. Send a message
result = client.send_message(
  A2A::Message.new(
    id: SecureRandom.uuid,
    role: A2A::Role::USER,
    parts: [A2A::Part::Text.new(text: "Summarise this document.")]
  )
)

case result
when A2A::Task    then puts "Task #{result.id}: #{result.status.state}"
when A2A::Message then puts result.parts.first.text
end
```

## What's included

### Client

`A2A::Client` covers all eleven A2A JSON-RPC methods:

| Method | Client call |
|--------|-------------|
| `SendMessage` | `client.send_message(message, configuration:, metadata:, tenant:)` |
| `SendStreamingMessage` | `client.send_streaming_message(message, ...) { \|event\| }` |
| `GetTask` | `client.get_task(id, history_length:)` |
| `ListTasks` | `client.list_tasks(page_size:, page_token:, status:, ...)` |
| `CancelTask` | `client.cancel_task(id_or_task)` |
| `SubscribeToTask` | `client.subscribe_to_task(id) { \|event\| }` |
| `CreatePushNotificationConfig` | `client.create_task_push_notification_config(config)` |
| `GetPushNotificationConfig` | `client.get_task_push_notification_config(task_id:, id:)` |
| `ListPushNotificationConfigs` | `client.list_task_push_notification_configs(task_id:)` |
| `DeletePushNotificationConfig` | `client.delete_task_push_notification_config(task_id:, id:)` |
| `GetExtendedAgentCard` | `client.get_extended_agent_card` |

The client accepts both a `Task` object and a plain string ID for operations
that reference tasks. Passing a terminal `Task` to `cancel_task` raises
`TaskNotCancelableError` locally without a network round-trip.

### Protocol bindings

```ruby
# JSON-RPC 2.0
protocol = A2A::Protocol::JsonRpc.new(
  url: "https://agent.example.com/rpc",
  headers: { "Authorization" => "Bearer token" }
)

# HTTP+JSON (REST-style)
protocol = A2A::Protocol::HttpJson.new(
  url: "https://agent.example.com",
  extensions: ["https://ext.example.com/v1"]
)

client = A2A::Client.new(protocol: protocol)
```

### Data model

All message types implement `.from_h(hash)` / `#to_h` for lossless
round-trip serialisation against the A2A wire format.

| Class | Purpose |
|-------|---------|
| `Task` | Unit of work; carries `id`, `status`, `artifacts`, `history` |
| `Task::Status` | State + optional message + timestamp |
| `Task::State` | String constants + `TERMINAL` / `RESUMABLE` collections |
| `Message` | User↔agent communication unit; carries `parts` |
| `Artifact` | Task output (not for communication) |
| `Part::Text` | Plain text content |
| `Part::Data` | Structured JSON content |
| `Part::File` | File by URL or base64 inline (`raw`/`url`, `filename`, `media_type`) |
| `Role` | `ROLE_USER` / `ROLE_AGENT` constants |

### Streaming

```ruby
client.send_streaming_message(message) do |event|
  case event.type
  when :status_update   then puts event.payload.status.state
  when :artifact_update then print event.payload.artifact.parts.first.text
  when :task            then puts "snapshot: #{event.payload.status.state}"
  when :message         then puts event.payload.parts.first.text
  end
end
```

Streaming stops automatically when a terminal state is detected. Without a
block, `send_streaming_message` returns a `Streaming::Subscription` that is
`Enumerable`.

### Server-side primitives

The gem includes three classes for building server handlers:

| Class | Purpose |
|-------|---------|
| `JSONRPCEnvelope` | Build success/error response envelopes; parse incoming request envelopes |
| `Operation::SendMessageRequest` | Deserialise incoming `SendMessage`/`SendStreamingMessage` params |
| `Streaming::SSEWriter` | Format `Streaming::Response` objects as SSE frames |

```ruby
# Parse an incoming request
id, method, params = A2A::JSONRPCEnvelope.parse_request(raw_hash)
req = A2A::Operation::SendMessageRequest.from_h(params)

# Build a response
A2A::JSONRPCEnvelope.success(id: id, result: { "task" => task.to_h })

# Write an SSE frame
A2A::Streaming::SSEWriter.encode(streaming_response, id: id)
```

### Task transitions (server-side)

`Task#transition_to` returns a new immutable `Task` — the original is never
mutated. Raises `TaskNotCancelableError` if the task is already terminal.

```ruby
task = task.transition_to(A2A::Task::State::WORKING)
task = task.transition_to(A2A::Task::State::COMPLETED, timestamp: Time.now.utc.iso8601)
```

### AgentCard builder

```ruby
card = A2A::AgentCard::Builder.new
  .name("My Agent")
  .description("Does useful things.")
  .version("1.0")
  .interface(url: "https://agent.example.com/rpc",
             protocol_binding: A2A::AgentInterface::JSONRPC,
             protocol_version: "1.0")
  .capabilities(streaming: true, push_notifications: true)
  .input_modes("text/plain")
  .output_modes("text/plain")
  .skill(id: "summarise", name: "Summarise",
         description: "Summarises documents", tags: ["text"])
  .build
```

### Push notifications

```ruby
# Dispatch from a server
dispatcher = A2A::PushNotification::Dispatcher.new
dispatcher.dispatch(config, streaming_response)

# Receive in a Rack app
use A2A::PushNotification::Receiver,
    path: "/a2a/webhook",
    credentials: ENV["WEBHOOK_TOKEN"] do |event|
  MyJob.perform_later(event.to_h.to_json)
end
```

### Security schemes

All five A2A security scheme types are modelled: `HTTPAuth`, `APIKey`,
`OAuth2` (authorization code, client credentials, device code),
`OpenIDConnect`, and `MutualTLS`. `SecurityScheme.from_h` dispatches on
the discriminator key.

### Errors

All errors inherit from `A2A::Error` and carry a `code` integer matching
the A2A spec's JSON-RPC error codes. `A2A.from_json_rpc_error(hash)` builds
the correct subclass from a raw error hash.

```
A2A::Error
├── A2A::TransportError
├── A2A::AuthenticationError          # HTTP 401
├── A2A::AuthorizationError           # HTTP 403
├── A2A::TaskNotFoundError            # -32001
├── A2A::TaskNotCancelableError       # -32002
├── A2A::PushNotificationNotSupportedError  # -32003
├── A2A::UnsupportedOperationError    # -32004
├── A2A::ContentTypeNotSupportedError # -32005
├── A2A::VersionNotSupportedError     # -32009
└── ... (full list in lib/a2a.rb)
```

## Examples

The [`examples/`](examples/) folder contains worked examples for each area of
the gem:

| File | Topic |
|------|-------|
| [`01_discovery.md`](examples/01_discovery.md) | Fetch an agent card; build a client from it |
| [`02_send_message.md`](examples/02_send_message.md) | Send text, file, and data messages; configuration; error handling |
| [`03_streaming.md`](examples/03_streaming.md) | Receive and emit SSE streams; `SSEWriter` |
| [`04_task_lifecycle.md`](examples/04_task_lifecycle.md) | Fetch, list, cancel, and transition tasks |
| [`05_push_notifications.md`](examples/05_push_notifications.md) | Register configs; dispatch and receive push events |
| [`06_agent_card.md`](examples/06_agent_card.md) | Declare and serve an `AgentCard` |
| [`07_server_side.md`](examples/07_server_side.md) | Parse requests; build responses; stream SSE from a Rack handler |
| [`08_security_schemes.md`](examples/08_security_schemes.md) | All five security scheme types; attach to a card |

## Development

```bash
bin/setup        # install dependencies
bin/console      # open a pry REPL with A2A loaded
bundle exec rake # run the test suite
bin/install-hooks # install the commit-msg hook (conventional commits)
```

## Releasing a new version

Commits must follow [Conventional Commits](https://www.conventionalcommits.org/).
Install the local commit-msg hook once after cloning:

```bash
bin/install-hooks
```

Valid types: `feat` (Added), `fix` (Fixed), `refactor`/`chore` (Changed),
`perf`, `revert`/`remove`, `deprecate`, `security`. Other types land in Other.
Merge commits and `Release vX.Y.Z` commits are exempt.

### Run the release script

```bash
bin/release patch   # 0.1.0 → 0.1.1
bin/release minor   # 0.1.0 → 0.2.0
bin/release major   # 0.1.0 → 1.0.0
```

The script will:

1. Abort if the working tree has uncommitted changes
2. Run the full test suite (`bundle exec rake spec`)
3. Parse `git log` since the previous tag and group commits by type
4. Show you the draft changelog entry and the new version, then ask for confirmation
5. Write the changelog entry into `CHANGELOG.md`
6. Bump `lib/a2a/version.rb`
7. Commit both files with the message `Release vx.y.z`
8. Create an annotated git tag `vx.y.z`
9. Push the commit and tag to `origin main`

Aborts if no conventional commits are found since the last tag.

### GitHub Actions publishes automatically

Pushing a `v*` tag triggers the publish workflow, which:

1. Verifies the tag is reachable from `main` (tags on other branches are rejected)
2. Runs the full test suite
3. Builds and pushes the gem to RubyGems via OIDC trusted publisher — no API key stored anywhere

`bin/release` is the only command you need to run.

### Preflight check (optional)

```bash
bundle exec rake preflight
```

Runs specs, checks that `[Unreleased]` is not empty, and verifies the working
tree is clean.

---

### Quick reference

| Command | What it does |
|---------|--------------|
| `bin/release patch` | Bump patch, update changelog, commit, tag, push |
| `bin/release minor` | Bump minor, update changelog, commit, tag, push |
| `bin/release major` | Bump major, update changelog, commit, tag, push |
| `bundle exec rake preflight` | Specs + changelog check + clean tree |
| `bundle exec rake spec` | Run tests only |
