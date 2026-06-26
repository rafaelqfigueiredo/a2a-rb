# frozen_string_literal: true

require "a2a/security_scheme/open_id_connect"

RSpec.describe A2A::SecurityScheme::OpenIDConnect do
  describe "#initialize" do
    it "sets required open_id_connect_url" do
      scheme = described_class.new(open_id_connect_url: "https://example.com/.well-known/openid-configuration")

      expect(scheme.open_id_connect_url).to eq "https://example.com/.well-known/openid-configuration"
    end

    it "defaults description to nil" do
      scheme = described_class.new(open_id_connect_url: "https://example.com/.well-known/openid-configuration")

      expect(scheme.description).to be_nil
    end

    it "accepts an optional description" do
      scheme = described_class.new(
        open_id_connect_url: "https://example.com/.well-known/openid-configuration",
        description:         "OIDC auth"
      )

      expect(scheme.description).to eq "OIDC auth"
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      scheme = described_class.from_h("openIdConnectUrl" => "https://example.com/.well-known/openid-configuration")

      expect(scheme.open_id_connect_url).to eq "https://example.com/.well-known/openid-configuration"
      expect(scheme.description).to be_nil
    end

    it "builds from a full hash" do
      scheme = described_class.from_h(
        "openIdConnectUrl" => "https://example.com/.well-known/openid-configuration",
        "description"      => "OIDC auth"
      )

      expect(scheme.open_id_connect_url).to eq "https://example.com/.well-known/openid-configuration"
      expect(scheme.description).to eq "OIDC auth"
    end

    it "raises KeyError when openIdConnectUrl is missing" do
      expect { described_class.from_h({}) }.to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serializes under the openIdConnectSecurityScheme key" do
      scheme = described_class.new(
        open_id_connect_url: "https://example.com/.well-known/openid-configuration",
        description:         "OIDC auth"
      )

      expect(scheme.to_h).to eq({
        "openIdConnectSecurityScheme" => {
          "openIdConnectUrl" => "https://example.com/.well-known/openid-configuration",
          "description"      => "OIDC auth"
        }
      })
    end

    it "round-trips through from_h" do
      original = described_class.new(open_id_connect_url: "https://example.com/.well-known/openid-configuration")
      restored = described_class.from_h(original.to_h["openIdConnectSecurityScheme"])

      expect(restored.open_id_connect_url).to eq original.open_id_connect_url
    end
  end
end
