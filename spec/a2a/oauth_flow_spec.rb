# frozen_string_literal: true

require "a2a/oauth_flow"

RSpec.describe A2A::OAuthFlow do
  describe ".from_h" do
    it "raises when no flow type is present" do
      expect { described_class.from_h({}) }.to raise_error(ArgumentError, /exactly one flow type/)
    end

    it "raises when more than one flow type is present" do
      auth_code = { "authorizationUrl" => "https://example.com/auth", "tokenUrl" => "https://example.com/token",
                    "scopes" => {} }
      hash = {
        "authorizationCode" => auth_code,
        "clientCredentials" => { "tokenUrl" => "https://example.com/token", "scopes" => {} }
      }

      expect { described_class.from_h(hash) }.to raise_error(ArgumentError, /exactly one flow type/)
    end

    it "builds authorizationCode flow" do
      hash = { "authorizationCode" => { "authorizationUrl" => "https://example.com/auth", "tokenUrl" => "https://example.com/token", "scopes" => {} } }

      result = described_class.from_h(hash)

      expect(result[:authorization_code]).to be_a(A2A::OAuthFlow::AuthorizationCode)
    end

    it "builds clientCredentials flow" do
      hash = { "clientCredentials" => { "tokenUrl" => "https://example.com/token", "scopes" => {} } }

      result = described_class.from_h(hash)

      expect(result[:client_credentials]).to be_a(A2A::OAuthFlow::ClientCredentials)
    end

    it "builds deviceCode flow" do
      hash = { "deviceCode" => { "deviceAuthorizationUrl" => "https://example.com/device", "tokenUrl" => "https://example.com/token", "scopes" => {} } }

      result = described_class.from_h(hash)

      expect(result[:device_code]).to be_a(A2A::OAuthFlow::DeviceCode)
    end

    it "rejects unrecognised flow keys as zero flows" do
      expect { described_class.from_h({ "unknown" => {} }) }.to raise_error(ArgumentError, /exactly one flow type/)
    end

    it "raises on deprecated implicit flow" do
      hash = { "implicit" => { "authorizationUrl" => "https://example.com/auth", "scopes" => {} } }

      expect { described_class.from_h(hash) }.to raise_error(ArgumentError, /deprecated/)
    end

    it "raises on deprecated password flow" do
      hash = { "password" => { "tokenUrl" => "https://example.com/token", "scopes" => {} } }

      expect { described_class.from_h(hash) }.to raise_error(ArgumentError, /deprecated/)
    end
  end
end
