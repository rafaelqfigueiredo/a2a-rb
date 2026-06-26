# frozen_string_literal: true

require "a2a/oauth_flow/authorization_code"

RSpec.describe A2A::OAuthFlow::AuthorizationCode do
  describe "#initialize" do
    it "sets required attributes" do
      flow = described_class.new(
        authorization_url: "https://example.com/auth",
        token_url: "https://example.com/token",
        scopes: { "read" => "Read access" }
      )

      expect(flow.authorization_url).to eq "https://example.com/auth"
      expect(flow.token_url).to eq "https://example.com/token"
      expect(flow.scopes).to eq({ "read" => "Read access" })
    end

    it "defaults optional attributes to nil" do
      flow = described_class.new(
        authorization_url: "https://example.com/auth",
        token_url: "https://example.com/token",
        scopes: {}
      )

      expect(flow.refresh_url).to be_nil
      expect(flow.pkce_required).to be_nil
    end

    it "accepts all optional attributes" do
      flow = described_class.new(
        authorization_url: "https://example.com/auth",
        token_url: "https://example.com/token",
        scopes: {},
        refresh_url: "https://example.com/refresh",
        pkce_required: true
      )

      expect(flow.refresh_url).to eq "https://example.com/refresh"
      expect(flow.pkce_required).to be true
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      flow = described_class.from_h(
        "authorizationUrl" => "https://example.com/auth",
        "tokenUrl" => "https://example.com/token",
        "scopes" => {}
      )

      expect(flow.authorization_url).to eq "https://example.com/auth"
      expect(flow.token_url).to eq "https://example.com/token"
      expect(flow.scopes).to eq({})
      expect(flow.refresh_url).to be_nil
      expect(flow.pkce_required).to be_nil
    end

    it "maps all optional fields" do
      flow = described_class.from_h(
        "authorizationUrl" => "https://example.com/auth",
        "tokenUrl" => "https://example.com/token",
        "scopes" => {},
        "refreshUrl" => "https://example.com/refresh",
        "pkceRequired" => true
      )

      expect(flow.refresh_url).to eq "https://example.com/refresh"
      expect(flow.pkce_required).to be true
    end

    it "raises KeyError when authorizationUrl is missing" do
      expect {
        described_class.from_h("tokenUrl" => "https://example.com/token", "scopes" => {})
      }.to raise_error(KeyError)
    end

    it "raises KeyError when tokenUrl is missing" do
      expect {
        described_class.from_h("authorizationUrl" => "https://example.com/auth", "scopes" => {})
      }.to raise_error(KeyError)
    end

    it "raises KeyError when scopes is missing" do
      expect {
        described_class.from_h("authorizationUrl" => "https://example.com/auth", "tokenUrl" => "https://example.com/token")
      }.to raise_error(KeyError)
    end
  end
end
