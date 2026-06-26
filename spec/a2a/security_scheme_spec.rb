# frozen_string_literal: true

require "a2a/security_scheme"

RSpec.describe A2A::SecurityScheme do
  describe ".from_h" do
    it "dispatches to APIKey" do
      scheme = described_class.from_h({
        "apiKeySecurityScheme" => { "name" => "X-API-Key", "location" => "header" }
      })

      expect(scheme).to be_a(A2A::SecurityScheme::APIKey)
      expect(scheme.name).to eq "X-API-Key"
    end

    it "dispatches to HTTPAuth" do
      scheme = described_class.from_h({
        "httpAuthSecurityScheme" => { "scheme" => "Bearer" }
      })

      expect(scheme).to be_a(A2A::SecurityScheme::HTTPAuth)
      expect(scheme.scheme).to eq "Bearer"
    end

    it "dispatches to OAuth2" do
      flows = { "authorizationCode" => { "authorizationUrl" => "https://example.com/auth", "tokenUrl" => "https://example.com/token", "scopes" => {} } }
      scheme = described_class.from_h({
        "oauth2SecurityScheme" => { "flows" => flows }
      })

      expect(scheme).to be_a(A2A::SecurityScheme::OAuth2)
      expect(scheme.flows[:authorization_code]).to be_a(A2A::OAuthFlow::AuthorizationCode)
    end

    it "dispatches to OpenIDConnect" do
      scheme = described_class.from_h({
        "openIdConnectSecurityScheme" => { "openIdConnectUrl" => "https://example.com/.well-known/openid-configuration" }
      })

      expect(scheme).to be_a(A2A::SecurityScheme::OpenIDConnect)
      expect(scheme.open_id_connect_url).to eq "https://example.com/.well-known/openid-configuration"
    end

    it "dispatches to MutualTLS" do
      scheme = described_class.from_h({ "mtlsSecurityScheme" => {} })

      expect(scheme).to be_a(A2A::SecurityScheme::MutualTLS)
    end

    it "raises ArgumentError for an unknown scheme key" do
      expect { described_class.from_h({ "unknownScheme" => {} }) }
        .to raise_error(ArgumentError, /unknown SecurityScheme/)
    end
  end
end
