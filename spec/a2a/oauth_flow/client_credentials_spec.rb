# frozen_string_literal: true

require "a2a/oauth_flow/client_credentials"

RSpec.describe A2A::OAuthFlow::ClientCredentials do
  describe "#initialize" do
    it "sets required attributes" do
      flow = described_class.new(
        token_url: "https://example.com/token",
        scopes: { "read" => "Read access" }
      )

      expect(flow.token_url).to eq "https://example.com/token"
      expect(flow.scopes).to eq({ "read" => "Read access" })
    end

    it "defaults optional attributes to nil" do
      flow = described_class.new(token_url: "https://example.com/token", scopes: {})

      expect(flow.refresh_url).to be_nil
    end

    it "accepts all optional attributes" do
      flow = described_class.new(
        token_url: "https://example.com/token",
        scopes: {},
        refresh_url: "https://example.com/refresh"
      )

      expect(flow.refresh_url).to eq "https://example.com/refresh"
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      flow = described_class.from_h(
        "tokenUrl" => "https://example.com/token",
        "scopes" => {}
      )

      expect(flow.token_url).to eq "https://example.com/token"
      expect(flow.scopes).to eq({})
      expect(flow.refresh_url).to be_nil
    end

    it "maps refreshUrl" do
      flow = described_class.from_h(
        "tokenUrl" => "https://example.com/token",
        "scopes" => {},
        "refreshUrl" => "https://example.com/refresh"
      )

      expect(flow.refresh_url).to eq "https://example.com/refresh"
    end

    it "raises KeyError when tokenUrl is missing" do
      expect { described_class.from_h("scopes" => {}) }.to raise_error(KeyError)
    end

    it "raises KeyError when scopes is missing" do
      expect { described_class.from_h("tokenUrl" => "https://example.com/token") }.to raise_error(KeyError)
    end
  end
end
