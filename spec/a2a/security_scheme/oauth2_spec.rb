# frozen_string_literal: true

require "a2a/security_scheme/oauth2"

RSpec.describe A2A::SecurityScheme::OAuth2 do
  let(:flows_hash) { { "authorizationCode" => { "authorizationUrl" => "https://example.com/auth", "tokenUrl" => "https://example.com/token", "scopes" => {} } } }
  let(:flows) { A2A::OAuthFlow.from_h(flows_hash) }

  describe "#initialize" do
    it "sets required flows" do
      scheme = described_class.new(flows: flows)

      expect(scheme.flows).to eq flows
    end

    it "raises ArgumentError when flows is a raw hash" do
      expect { described_class.new(flows: { "authorizationCode" => {} }) }
        .to raise_error(ArgumentError, /exactly one OAuthFlow entry/)
    end

    it "raises ArgumentError when flows is empty" do
      expect { described_class.new(flows: {}) }
        .to raise_error(ArgumentError, /exactly one OAuthFlow entry/)
    end

    it "defaults optional attributes to nil" do
      scheme = described_class.new(flows: flows)

      expect(scheme.oauth2_metadata_url).to be_nil
      expect(scheme.description).to be_nil
    end

    it "accepts all optional attributes" do
      scheme = described_class.new(
        flows: flows,
        oauth2_metadata_url: "https://example.com/.well-known/oauth-authorization-server",
        description: "OAuth2 auth"
      )

      expect(scheme.oauth2_metadata_url).to eq "https://example.com/.well-known/oauth-authorization-server"
      expect(scheme.description).to eq "OAuth2 auth"
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      scheme = described_class.from_h("flows" => flows_hash)

      expect(scheme.flows[:authorization_code]).to be_a(A2A::OAuthFlow::AuthorizationCode)
      expect(scheme.oauth2_metadata_url).to be_nil
    end

    it "builds from a full hash" do
      scheme = described_class.from_h(
        "flows" => flows_hash,
        "oauth2MetadataUrl" => "https://example.com/.well-known/oauth-authorization-server",
        "description" => "OAuth2 auth"
      )

      expect(scheme.oauth2_metadata_url).to eq "https://example.com/.well-known/oauth-authorization-server"
      expect(scheme.description).to eq "OAuth2 auth"
    end

    it "raises KeyError when flows is missing" do
      expect { described_class.from_h({}) }.to raise_error(KeyError)
    end

    it "raises ArgumentError when flows is empty" do
      expect { described_class.from_h("flows" => {}) }.to raise_error(ArgumentError, /exactly one flow type/)
    end
  end

  describe "#to_h" do
    it "serializes under the oauth2SecurityScheme key" do
      scheme = described_class.new(flows: flows, description: "OAuth2 auth")
      result = scheme.to_h

      expect(result["oauth2SecurityScheme"]["flows"]).to eq({ "authorizationCode" => flows[:authorization_code].to_h })
      expect(result["oauth2SecurityScheme"]["oauth2MetadataUrl"]).to be_nil
      expect(result["oauth2SecurityScheme"]["description"]).to eq "OAuth2 auth"
    end

    it "round-trips through from_h" do
      original = described_class.from_h("flows" => flows_hash)
      restored = described_class.from_h(original.to_h["oauth2SecurityScheme"])

      expect(restored.flows[:authorization_code].authorization_url).to eq "https://example.com/auth"
      expect(restored.flows[:authorization_code].token_url).to eq "https://example.com/token"
    end
  end
end
