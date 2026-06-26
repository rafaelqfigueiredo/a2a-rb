# Discovery

Fetch an agent's public card from its well-known URL, then optionally upgrade
to the extended (authenticated) card.

## Fetch the public card

```ruby
require "a2a"

card = A2A::Discovery.fetch("https://agent.example.com")

puts card.name          # "Weather Agent"
puts card.version       # "1.0"
puts card.description
puts card.skills.map(&:id)
puts card.capabilities.streaming
```

`Discovery.fetch` issues a single `GET /.well-known/agent-card.json` with no
authentication. The returned `AgentCard` contains everything needed to decide
whether to call the agent.

## Inspect what the agent supports

```ruby
card.supported_interfaces.each do |iface|
  puts "#{iface.protocol_binding} at #{iface.url}"
end
# JSON-RPC at https://agent.example.com/rpc
# HTTP+JSON at https://agent.example.com/http

puts card.capabilities.streaming         # true
puts card.capabilities.push_notifications # false

card.skills.each do |skill|
  puts "#{skill.id}: #{skill.description} (tags: #{skill.tags.join(', ')})"
end
```

## Fetch the extended card (requires auth)

If the public card declares `capabilities.extendedAgentCard: true`, the agent
exposes a richer card behind authentication via `GetExtendedAgentCard`.

```ruby
card = A2A::Discovery.fetch_extended(
  "https://agent.example.com",
  headers: { "Authorization" => "Bearer my-token" }
)

# The extended card may contain additional skills, security schemes,
# or documentation not present on the public card.
puts card.security_schemes.keys
```

`fetch_extended` fetches the public card first to negotiate the protocol
binding, then calls `GetExtendedAgentCard` on the resulting `Client`.

## Build a client directly from the card

```ruby
card = A2A::Discovery.fetch("https://agent.example.com")

# Negotiate the best available binding (JSON-RPC preferred over HTTP+JSON)
client = A2A::Client.from_agent_card(card)

# Or force a specific binding
client = A2A::Client.from_agent_card(
  card,
  preference: [A2A::AgentInterface::HTTP_JSON]
)
```

`from_agent_card` validates the protocol version and raises
`VersionNotSupportedError` if the agent declares a version the gem does not
support.
