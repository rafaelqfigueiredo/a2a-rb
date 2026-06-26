# AgentCard — declaring and publishing your agent

An `AgentCard` describes your agent to the world. It is served unauthenticated
at `GET /.well-known/agent-card.json` and tells callers what your agent can do,
which protocol bindings it supports, and how to authenticate.

## Build a card with the fluent builder

```ruby
require "a2a"

card = A2A::AgentCard::Builder.new
  .name("Document Intelligence Agent")
  .description("Extracts, summarises, and classifies documents.")
  .version("1.0")
  .interface(
    url: "https://agent.example.com/rpc",
    protocol_binding: A2A::AgentInterface::JSONRPC,
    protocol_version: "1.0"
  )
  .interface(
    url: "https://agent.example.com",
    protocol_binding: A2A::AgentInterface::HTTP_JSON,
    protocol_version: "1.0"
  )
  .capabilities(streaming: true, push_notifications: true, extended_agent_card: true)
  .input_modes("text/plain", "application/pdf")
  .output_modes("text/plain", "application/json")
  .skill(
    id: "summarise",
    name: "Summarise",
    description: "Returns a concise summary of the provided document.",
    tags: ["text", "summarisation"],
    input_modes: ["text/plain", "application/pdf"],
    output_modes: ["text/plain"]
  )
  .skill(
    id: "classify",
    name: "Classify",
    description: "Classifies a document into one of the configured categories.",
    tags: ["text", "classification"],
    input_modes: ["text/plain"],
    output_modes: ["application/json"]
  )
  .provider("Acme Corp", url: "https://acme.example.com")
  .documentation_url("https://docs.acme.example.com/agents/document-intelligence")
  .build
```

## Add security schemes

```ruby
card = A2A::AgentCard::Builder.new
  .name("Secure Agent")
  .description("Requires Bearer authentication.")
  .version("1.0")
  .interface(url: "https://agent.example.com/rpc",
             protocol_binding: A2A::AgentInterface::JSONRPC, protocol_version: "1.0")
  .capabilities
  .input_modes("text/plain")
  .output_modes("text/plain")
  .skill(id: "s1", name: "Task", description: "Does a task", tags: ["general"])
  .security_scheme(
    "bearerAuth",
    A2A::SecurityScheme::HTTPAuth.new(scheme: "Bearer", bearer_format: "JWT")
  )
  .security([{ "bearerAuth" => [] }])
  .build
```

## Serve the card in Rails

```ruby
# config/routes.rb
get "/.well-known/agent-card.json", to: "agent_card#show"

# app/controllers/agent_card_controller.rb
class AgentCardController < ApplicationController
  CARD = A2A::AgentCard::Builder.new
    .name(ENV.fetch("AGENT_NAME"))
    # ... rest of builder chain
    .build

  def show
    render json: CARD.to_h
  end
end
```

Build the card once at boot and freeze it — `to_h` is called on every request
but the card itself never changes.

## Serve the card in pure Rack

```ruby
# config.ru
require "a2a"
require "json"

CARD = A2A::AgentCard::Builder.new
  .name("My Agent")
  # ...
  .build

run lambda { |env|
  if env["PATH_INFO"] == "/.well-known/agent-card.json"
    [200, { "Content-Type" => "application/json" }, [JSON.generate(CARD.to_h)]]
  else
    [404, {}, ["not found"]]
  end
}
```

## Round-trip serialisation

`AgentCard.from_h` and `#to_h` are the canonical serialisation pair.

```ruby
json_hash = card.to_h
JSON.generate(json_hash)   # write to response

restored = A2A::AgentCard.from_h(JSON.parse(json_string))
restored.name == card.name # true
```

## Canonical JSON for JWS signing

`#canonical_json` returns RFC 8785 key-sorted JSON with `"signatures"` excluded,
suitable as the JWS payload.

```ruby
payload = card.canonical_json
# Sign with your JWS library of choice, then attach the signature(s) to the card.
```
