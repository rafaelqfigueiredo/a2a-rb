# frozen_string_literal: true

require "a2a/security_scheme/http_auth"

RSpec.describe A2A::SecurityScheme::HTTPAuth do
  describe "#initialize" do
    it "sets required scheme" do
      scheme = described_class.new(scheme: "Bearer")

      expect(scheme.scheme).to eq "Bearer"
    end

    it "defaults optional attributes to nil" do
      scheme = described_class.new(scheme: "Bearer")

      expect(scheme.bearer_format).to be_nil
      expect(scheme.description).to be_nil
    end

    it "accepts all optional attributes" do
      scheme = described_class.new(scheme: "Bearer", bearer_format: "JWT", description: "Bearer token")

      expect(scheme.bearer_format).to eq "JWT"
      expect(scheme.description).to eq "Bearer token"
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      scheme = described_class.from_h("scheme" => "Bearer")

      expect(scheme.scheme).to eq "Bearer"
      expect(scheme.bearer_format).to be_nil
      expect(scheme.description).to be_nil
    end

    it "builds from a full hash" do
      scheme = described_class.from_h(
        "scheme"       => "Bearer",
        "bearerFormat" => "JWT",
        "description"  => "Bearer token"
      )

      expect(scheme.scheme).to eq "Bearer"
      expect(scheme.bearer_format).to eq "JWT"
      expect(scheme.description).to eq "Bearer token"
    end

    it "raises KeyError when scheme is missing" do
      expect { described_class.from_h({}) }.to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serializes under the httpAuthSecurityScheme key" do
      scheme = described_class.new(scheme: "Bearer", bearer_format: "JWT", description: "Bearer token")

      expect(scheme.to_h).to eq({
        "httpAuthSecurityScheme" => {
          "scheme"       => "Bearer",
          "bearerFormat" => "JWT",
          "description"  => "Bearer token"
        }
      })
    end

    it "includes nil optional fields" do
      scheme = described_class.new(scheme: "Basic")

      inner = scheme.to_h["httpAuthSecurityScheme"]
      expect(inner["bearerFormat"]).to be_nil
      expect(inner["description"]).to be_nil
    end

    it "round-trips through from_h" do
      original = described_class.new(scheme: "Bearer", bearer_format: "JWT")
      restored = described_class.from_h(original.to_h["httpAuthSecurityScheme"])

      expect(restored.scheme).to eq original.scheme
      expect(restored.bearer_format).to eq original.bearer_format
    end
  end
end
