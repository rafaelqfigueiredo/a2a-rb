# Security schemes

Security schemes declare how callers must authenticate. They live in the
`AgentCard` and are serialised as part of the card's JSON. The gem models all
five scheme types defined in the A2A spec.

## HTTP Bearer (most common)

```ruby
require "a2a"

scheme = A2A::SecurityScheme::HTTPAuth.new(
  scheme: "Bearer",
  bearer_format: "JWT",
  description: "JWT issued by the ACME IdP"
)

scheme.to_h
# {
#   "httpAuthSecurityScheme" => {
#     "scheme" => "Bearer",
#     "bearerFormat" => "JWT",
#     "description" => "JWT issued by the ACME IdP"
#   }
# }
```

## API key

```ruby
scheme = A2A::SecurityScheme::APIKey.new(
  name: "X-API-Key",
  location: "header",
  description: "API key passed in the X-API-Key header"
)
```

## OAuth 2.0 — authorization code

```ruby
flows = {
  authorization_code: A2A::OAuthFlow::AuthorizationCode.new(
    authorization_url: "https://idp.example.com/oauth2/authorize",
    token_url: "https://idp.example.com/oauth2/token",
    scopes: { "read:tasks" => "Read tasks", "write:tasks" => "Create and cancel tasks" },
    pkce_required: true
  )
}

scheme = A2A::SecurityScheme::OAuth2.new(flows: flows)
```

## OAuth 2.0 — client credentials

```ruby
flows = {
  client_credentials: A2A::OAuthFlow::ClientCredentials.new(
    token_url: "https://idp.example.com/oauth2/token",
    scopes: { "agent:invoke" => "Invoke the agent" }
  )
}

scheme = A2A::SecurityScheme::OAuth2.new(flows: flows)
```

## OAuth 2.0 — device code

```ruby
flows = {
  device_code: A2A::OAuthFlow::DeviceCode.new(
    device_authorization_url: "https://idp.example.com/oauth2/device_authorize",
    token_url: "https://idp.example.com/oauth2/token",
    scopes: { "read:tasks" => "Read tasks" }
  )
}

scheme = A2A::SecurityScheme::OAuth2.new(flows: flows)
```

Attempting to use the deprecated `implicit` or `password` flows raises
`ArgumentError` with an explicit "deprecated" message.

## OpenID Connect

```ruby
scheme = A2A::SecurityScheme::OpenIDConnect.new(
  open_id_connect_url: "https://idp.example.com/.well-known/openid-configuration"
)
```

## Mutual TLS

```ruby
scheme = A2A::SecurityScheme::MutualTLS.new(
  description: "Client certificate issued by ACME CA"
)
```

## Attaching schemes to a card

```ruby
card = A2A::AgentCard::Builder.new
  .name("Secure Agent")
  .description("API key protected agent")
  .version("1.0")
  .interface(url: "https://agent.example.com/rpc",
             protocol_binding: A2A::AgentInterface::JSONRPC, protocol_version: "1.0")
  .capabilities
  .input_modes("text/plain")
  .output_modes("text/plain")
  .skill(id: "s1", name: "Query", description: "Answers questions", tags: ["qa"])
  .security_scheme("apiKey", A2A::SecurityScheme::APIKey.new(name: "X-API-Key", location: "header"))
  .security([{ "apiKey" => [] }])
  .build
```

## Deserialising a scheme from JSON

`SecurityScheme.from_h` dispatches on the discriminator key in the hash.

```ruby
hash = {
  "httpAuthSecurityScheme" => { "scheme" => "Bearer", "bearerFormat" => "JWT" }
}

scheme = A2A::SecurityScheme.from_h(hash)
# => #<A2A::SecurityScheme::HTTPAuth scheme="Bearer" bearer_format="JWT">
```
