# a2a-rb — Claude harness

## Project overview

Ruby gem implementing the [A2A protocol spec v1.0](https://a2a-protocol.org/latest/specification/) — a JSON-RPC 2.0 standard for agent-to-agent communication.

The gem covers:
- **Data model** — every message type from the spec, with `.from_h` / `#to_h` serialisation
- **Client** — all 11 JSON-RPC methods, both JSON-RPC 2.0 and HTTP+JSON bindings
- **Streaming** — SSE parser (`SseParser`) and server-side writer (`SSEWriter`), `Subscription` Enumerable
- **Push notifications** — `Dispatcher` (outbound HTTP POST) and `Receiver` (Rack middleware)
- **Server-side primitives** — `JSONRPCEnvelope`, `SendMessageRequest`, `Task#transition_to`
- **AgentCard builder** — fluent `AgentCard::Builder` for declaring an agent's card at boot time
- **Discovery** — `Discovery.fetch` / `fetch_extended`

Ruby 3.4+. No runtime dependencies (Rack is a dev dependency for the receiver tests).

## Running tests

```bash
bundle exec rake           # default: runs spec
bundle exec rake spec      # run tests only
bundle exec rake preflight # specs + changelog check + clean tree
bundle exec rubocop        # lint
```

Tests use RSpec with random ordering. No mocking of internal classes — only `webmock` for HTTP integration tests.

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/). Run `bin/install-hooks` once after cloning to install the local commit-msg hook.

Valid types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `ci`, `build`, `revert`.

`bin/release` reads `git log` since the last tag to auto-generate the changelog entry.

## Code style

- `frozen_string_literal: true` on every file.
- RuboCop enforced. Config in `.rubocop.yml` — 120-char line limit, double-quoted strings, `NewCops: enable`. Specs and gemspec are excluded from most metrics cops.
- **Do not align hash values with extra spaces.**

```ruby
# BAD
{ key:      1, long_key: 2 }

# GOOD
{ key: 1, long_key: 2 }
```

## Architecture

### Module layout

```
A2A
├── Task                        # unit of work; server-generated id
│   ├── State                   # string constants + TERMINAL / RESUMABLE collections
│   └── Status                  # state + optional message + timestamp
├── Message                     # user↔agent communication unit
├── Artifact                    # task output (not for communication)
├── Part                        # content container (factory via .from_h)
│   ├── Part::Text
│   ├── Part::Data               # structured JSON
│   └── Part::File               # raw bytes (base64) or URL; filename/media_type flat on this class
├── Role                        # ROLE_USER / ROLE_AGENT constants
├── Streaming
│   ├── Response                 # discriminated union: task | message | status_update | artifact_update
│   ├── StatusUpdateEvent
│   ├── ArtifactUpdateEvent
│   ├── Subscription             # Enumerable wrapper; auto-terminates on terminal state
│   ├── SseParser                # client-side SSE line parser
│   └── SSEWriter                # server-side SSE frame serialiser
├── PushNotification
│   ├── Config
│   ├── AuthenticationInfo
│   ├── Dispatcher               # fires HTTP POST to a registered webhook
│   └── Receiver                 # Rack middleware for receiving push events
├── JSONRPCEnvelope              # server-side: build success/error envelopes, parse requests
├── AgentCard                   # discovery metadata published at /.well-known/agent-card.json
│   ├── Builder                  # fluent builder for declaring a card at boot time
│   ├── Signature
│   └── Verifier                 # stub — raises NotImplementedError (JWS §8.4 not implemented)
├── AgentCapabilities
├── AgentInterface               # protocol binding (JSONRPC | HTTP+JSON | gRPC) + URL
├── AgentProvider
├── AgentSkill
├── AgentExtension
├── OAuthFlow
│   ├── AuthorizationCode
│   ├── ClientCredentials
│   └── DeviceCode               # implicit/password raise ArgumentError (deprecated by spec)
├── SecurityScheme               # factory via .from_h; dispatches on discriminator key
│   ├── APIKey
│   ├── HTTPAuth
│   ├── OAuth2
│   ├── OpenIDConnect
│   └── MutualTLS
├── SecurityRequirement
├── Protocol::JsonRpc            # JSON-RPC 2.0 transport
├── Protocol::HttpJson           # HTTP+JSON transport (REST-style paths)
├── Operation::*                 # one class per JSON-RPC method (client-side)
│   └── SendMessageRequest       # server-side: deserialises incoming SendMessage params
├── Client                       # high-level client; negotiates binding from AgentCard
├── Discovery                    # fetches AgentCard from /.well-known/agent-card.json
└── Versioning                   # version constants + validate!
```

### Serialisation conventions

Every class implements the same two-method contract:

| Method | Direction | Notes |
|--------|-----------|-------|
| `.from_h(hash)` | JSON hash → Ruby object | `hash.fetch(key)` for required fields (raises `KeyError`); `hash[key]` for optional. Unknown keys are silently ignored. |
| `#to_h` | Ruby object → JSON hash | Always calls `.compact` to drop `nil` optional fields. Keys are camelCase strings matching the spec. |

**Key name mapping** — Ruby uses `snake_case` attributes; the wire format uses `camelCase` JSON keys:

| Ruby attr | JSON key |
|-----------|----------|
| `id` | `"messageId"` (Message), `"artifactId"` (Artifact) |
| `context_id` | `"contextId"` |
| `task_id` | `"taskId"` |
| `push_notifications` | `"pushNotifications"` |
| `last_chunk` | `"lastChunk"` |
| `media_type` | `"mediaType"` |

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

### Server-side primitives

Three classes exist specifically for building server handlers — they have no client-side equivalent:

| Class | Purpose |
|-------|---------|
| `JSONRPCEnvelope` | `.success(id:, result:)`, `.error(id:, error:)`, `.parse_request(hash)` |
| `Operation::SendMessageRequest` | `.from_h(params_hash)` → typed request object |
| `Streaming::SSEWriter` | `.encode(response, id:)`, `.encode_error(error, id:)` → SSE frame string |

`SSEWriter` is the server-side mirror of `SseParser`. A round-trip `SSEWriter → SseParser` is lossless.

### Task lifecycle

```
SUBMITTED → WORKING → COMPLETED  (terminal)
                    ↘ FAILED      (terminal)
                    ↘ CANCELED    (terminal)
                    ↘ REJECTED    (terminal)
                    ↘ INPUT_REQUIRED  (resumable → WORKING)
                    ↘ AUTH_REQUIRED   (resumable → WORKING)
UNSPECIFIED  (sentinel; avoid in production)
```

- `Task::State::TERMINAL  = [COMPLETED, FAILED, CANCELED, REJECTED]`
- `Task::State::RESUMABLE = [INPUT_REQUIRED, AUTH_REQUIRED]`
- `Task#terminal?` delegates to `status.terminal?`
- `Task#transition_to(state, message: nil, timestamp: nil)` returns a new immutable `Task`. Raises `ArgumentError` for unknown states, `TaskNotCancelableError` if already terminal. Does **not** dispatch push notifications — that is the caller's responsibility.

### HTTP+JSON paths (proto `google.api.http` annotations)

| Operation | Method | Path |
|-----------|--------|------|
| SendMessage | POST | `/message:send` |
| SendStreamingMessage | POST | `/message:stream` |
| GetTask | GET | `/tasks/{id}` |
| ListTasks | GET | `/tasks` |
| CancelTask | POST | `/tasks/{id}:cancel` |
| SubscribeToTask | GET | `/tasks/{id}:subscribe` |
| CreatePushNotificationConfig | POST | `/tasks/{id}/pushNotificationConfigs` |
| GetPushNotificationConfig | GET | `/tasks/{id}/pushNotificationConfigs/{config_id}` |
| ListPushNotificationConfigs | GET | `/tasks/{id}/pushNotificationConfigs` |
| DeletePushNotificationConfig | DELETE | `/tasks/{id}/pushNotificationConfigs/{config_id}` |
| GetExtendedAgentCard | GET | `/extendedAgentCard` |

### AgentCard::Builder

Fluent builder — all methods return `self`. Call `.build` at the end. Accepts both object and kwargs forms for interfaces, skills, and capabilities. Validates via `AgentCard.new` so errors surface at `.build` time.

```ruby
card = A2A::AgentCard::Builder.new
  .name("My Agent").description("...").version("1.0")
  .interface(url: "...", protocol_binding: A2A::AgentInterface::JSONRPC, protocol_version: "1.0")
  .capabilities(streaming: true)
  .input_modes("text/plain").output_modes("text/plain")
  .skill(id: "s1", name: "Skill", description: "...", tags: ["general"])
  .build
```

### Error classes

```ruby
A2A::Error                               # base; carries :code and :details
A2A::TransportError                      # HTTP / network layer
A2A::AuthenticationError                 # HTTP 401
A2A::AuthorizationError                  # HTTP 403
A2A::ValidationError
A2A::JSONParseError                      # -32700
A2A::InvalidRequestError                 # -32600
A2A::MethodNotFoundError                 # -32601
A2A::InvalidParamsError                  # -32602
A2A::InternalError                       # -32603
A2A::TaskNotFoundError                   # -32001
A2A::TaskNotCancelableError              # -32002
A2A::PushNotificationNotSupportedError   # -32003
A2A::UnsupportedOperationError           # -32004
A2A::ContentTypeNotSupportedError        # -32005
A2A::InvalidAgentResponseError           # -32006
A2A::ExtendedAgentCardNotConfiguredError # -32007
A2A::ExtensionSupportRequiredError       # -32008
A2A::VersionNotSupportedError            # -32009
```

Build from a JSON-RPC error hash: `A2A.from_json_rpc_error(hash)`.
Build a response envelope from an error: `A2A::JSONRPCEnvelope.error(id:, error:)`.

### Not yet implemented

- `AgentCard::Verifier` — JWS signature verification (§8.4) raises `NotImplementedError`. Requires deciding on a `jwt` gem dependency.
- gRPC binding — `AgentInterface::GRPC` is a constant but no transport exists.
