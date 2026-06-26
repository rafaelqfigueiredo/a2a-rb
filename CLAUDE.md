# a2a-rb — Claude harness

## Project overview

Ruby gem implementing the [A2A protocol spec v1.0](https://a2a-protocol.org/latest/specification/) — a JSON-RPC 2.0 standard for agent-to-agent communication. The gem is a **data-model and serialisation library only**: no HTTP client or server is included yet. Every class maps 1-to-1 to a Protobuf message in the canonical spec proto file.

Ruby 3.4+. No runtime dependencies.

## Running tests

```bash
bundle exec rake          # default: runs spec
bundle exec rake spec     # run tests only
bundle exec rake preflight # specs + changelog check + clean tree
```

Tests use RSpec with random ordering. No mocking of internal classes — only `webmock` for future HTTP work.

## Code style

- `frozen_string_literal: true` on every file.
- RuboCop enforced (`bundle exec rubocop`). Config in `.rubocop.yml` — 120-char line limit, double-quoted strings, `NewCops: enable`. Specs and gemspec are excluded from most metrics cops.
- **Do not align hash values with extra spaces.**

```ruby
# BAD
{
  key:      1,
  long_key: 2
}

# GOOD
{
  key: 1,
  long_key: 2
}
```

## Architecture

### Module layout

```
A2A
├── Task                     # unit of work; server-generated id
│   ├── State                # string constants (TASK_STATE_*)
│   └── Status               # state + optional message + timestamp
├── Message                  # user↔agent communication unit
├── Artifact                 # task output (not for communication)
├── Part                     # content container (factory via .from_h)
│   ├── Part::Text
│   ├── Part::Data           # structured JSON
│   └── Part::File           # raw bytes (base64) or URL
│       └── Part::File::Content
├── Role                     # ROLE_USER / ROLE_AGENT constants
├── Streaming
│   ├── Response             # discriminated union: task | message | status_update | artifact_update
│   ├── StatusUpdateEvent
│   └── ArtifactUpdateEvent
├── PushNotification
│   ├── Config
│   └── AuthenticationInfo
├── AgentCard                # discovery metadata published at /.well-known/agent-card.json
├── AgentCapabilities        # streaming / pushNotifications / extendedAgentCard flags
├── AgentInterface           # protocol binding (JSON-RPC, gRPC, HTTP/REST) + URL
├── AgentProvider
├── AgentSkill               # declared skill with id, tags, input/output modes
├── AgentExtension
├── OAuthFlow
│   ├── AuthorizationCode
│   ├── ClientCredentials
│   └── DeviceCode
├── SecurityScheme           # factory via .from_h; dispatches on discriminator key
│   ├── APIKey
│   ├── HTTPAuth
│   ├── OAuth2
│   ├── OpenIDConnect
│   └── MutualTLS
└── SecurityRequirement
```

### Serialisation conventions

Every class implements the same two-method contract:

| Method | Direction | Notes |
|--------|-----------|-------|
| `.from_h(hash)` | JSON hash → Ruby object | `hash.fetch(key)` for required fields (raises `KeyError`); `hash[key]` for optional. Unknown keys are silently ignored. |
| `#to_h` | Ruby object → JSON hash | Always calls `.compact` to drop `nil` optional fields. Keys are camelCase strings matching the spec. |

**Key name mapping** — Ruby uses `snake_case` attributes; the wire format uses `camelCase` JSON keys. Examples:

| Ruby attr | JSON key |
|-----------|----------|
| `id` | `"messageId"` (Message), `"artifactId"` (Artifact) |
| `context_id` | `"contextId"` |
| `task_id` | `"taskId"` |
| `push_notifications` | `"pushNotifications"` |
| `last_chunk` | `"lastChunk"` |

### Discriminated-union deserialisers

`Part`, `SecurityScheme`, and `Streaming::Response` are abstract — `.from_h` inspects the hash keys and delegates to the concrete subclass. Follow the same pattern when adding new union types:

```ruby
BUILDERS = {
  "knownKey" => ->(v) { ConcreteClass.from_h(v) }
}.freeze

def self.from_h(hash)
  key, builder = BUILDERS.find { |k, _| hash.key?(k) }
  raise ArgumentError, "unknown type: #{hash.keys.inspect}" unless key
  builder.call(hash[key])
end
```

## A2A protocol quick-reference

### Task lifecycle (TaskState)

```
SUBMITTED → WORKING → COMPLETED  (terminal)
                    ↘ FAILED      (terminal)
                    ↘ CANCELED    (terminal)
                    ↘ REJECTED    (terminal)
                    ↘ INPUT_REQUIRED  (resumes to WORKING)
                    ↘ AUTH_REQUIRED   (resumes to WORKING)
UNSPECIFIED  (sentinel; avoid in production)
```

`Task::State::TERMINAL` = `[COMPLETED, FAILED, CANCELED, REJECTED]`.
`Task::Status#terminal?` delegates to `Task::State.terminal?`.

### JSON-RPC methods (spec §4)

| Method | Returns |
|--------|---------|
| `SendMessage` | `Task` or `Message` |
| `SendStreamingMessage` | stream of `Streaming::Response` |
| `GetTask` | `Task` |
| `ListTasks` | paginated `Task` list |
| `CancelTask` | `Task` |
| `SubscribeToTask` | stream of `Streaming::Response` |
| `CreatePushNotificationConfig` | `PushNotification::Config` |
| `GetPushNotificationConfig` | `PushNotification::Config` |
| `ListPushNotificationConfigs` | list of configs |
| `DeletePushNotificationConfig` | — |
| `GetExtendedAgentCard` | `AgentCard` |

### Streaming response types (`Streaming::Response`)

The `type` symbol and the corresponding payload class:

| `type` | payload class | JSON key in wire frame |
|--------|--------------|------------------------|
| `:task` | `Task` | `"task"` |
| `:message` | `Message` | `"message"` |
| `:status_update` | `Streaming::StatusUpdateEvent` | `"statusUpdate"` |
| `:artifact_update` | `Streaming::ArtifactUpdateEvent` | `"artifactUpdate"` |

Use `response.status_update?` / `response.artifact_update?` predicates, not `type ==`.

### ArtifactUpdateEvent fields of note

| Field | Ruby | Meaning |
|-------|------|---------|
| `append` | bool, default `false` | Parts should be appended to previous chunk |
| `last_chunk` | bool, default `false` | This is the final chunk for the artifact |

Streaming agents emit multiple `ArtifactUpdateEvent`s per artifact. Reassemble by accumulating parts until `last_chunk: true`.

### Part types and detection

| Part class | Detected by key | Wire representation |
|------------|-----------------|---------------------|
| `Part::Text` | `"text"` | `{ "text": "..." }` |
| `Part::Data` | `"data"` | `{ "data": { ... } }` |
| `Part::File` | `"raw"` or `"url"` | `{ "raw": "<base64>", "mimeType": "..." }` or `{ "url": "..." }` |

### AgentCard discovery

Served at `GET /.well-known/agent-card.json` (unauthenticated). `GetExtendedAgentCard` returns a richer version requiring auth. Required fields: `name`, `description`, `version`, `supportedInterfaces`, `capabilities`, `skills`, `defaultInputModes`, `defaultOutputModes`.

### Error classes

```ruby
A2A::Error                          # base; carries :code and :details
A2A::TransportError                 # HTTP / network layer
A2A::AuthenticationError
A2A::AuthorizationError
A2A::ValidationError
A2A::TaskNotFoundError
A2A::TaskNotCancelableError
A2A::PushNotificationNotSupportedError
A2A::UnsupportedOperationError
A2A::ContentTypeNotSupportedError
A2A::InvalidAgentResponseError
A2A::ExtendedAgentCardNotConfiguredError
A2A::ExtensionSupportRequiredError
A2A::VersionNotSupportedError
```

Build from a JSON-RPC error hash: `A2A.from_json_rpc_error(hash)`.

### Service parameters (protocol headers)

| Parameter | Header / metadata key | Notes |
|-----------|-----------------------|-------|
| Protocol version | `A2A-Version` | `"Major.Minor"` format; empty → treated as `0.3` |
| Extensions | `A2A-Extensions` | Comma-separated extension URIs |

## Spec reference

- Canonical proto: `spec/a2a.proto` in the upstream repo (not vendored here).
- Full spec: https://a2a-protocol.org/latest/specification/
- This gem targets spec version `1.0` (`A2A::SPEC_VERSION`).
