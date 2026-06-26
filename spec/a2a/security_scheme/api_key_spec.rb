# frozen_string_literal: true

require "a2a/security_scheme/api_key"

RSpec.describe A2A::SecurityScheme::APIKey do
  describe "#initialize" do
    it "sets required attributes" do
      scheme = described_class.new(name: "X-API-Key", location: "header")

      expect(scheme.name).to eq "X-API-Key"
      expect(scheme.location).to eq "header"
    end

    it "defaults description to nil" do
      scheme = described_class.new(name: "X-API-Key", location: "header")

      expect(scheme.description).to be_nil
    end

    it "accepts an optional description" do
      scheme = described_class.new(name: "X-API-Key", location: "query", description: "An API key")

      expect(scheme.description).to eq "An API key"
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      scheme = described_class.from_h("name" => "X-API-Key", "location" => "header")

      expect(scheme.name).to eq "X-API-Key"
      expect(scheme.location).to eq "header"
      expect(scheme.description).to be_nil
    end

    it "builds from a full hash" do
      scheme = described_class.from_h(
        "name"        => "X-API-Key",
        "location"          => "cookie",
        "description" => "An API key"
      )

      expect(scheme.location).to eq "cookie"
      expect(scheme.description).to eq "An API key"
    end

    it "raises KeyError when name is missing" do
      expect { described_class.from_h("location" => "header") }.to raise_error(KeyError)
    end

    it "raises KeyError when in is missing" do
      expect { described_class.from_h("name" => "X-API-Key") }.to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serializes under the apiKeySecurityScheme key" do
      scheme = described_class.new(name: "X-API-Key", location: "header", description: "An API key")

      expect(scheme.to_h).to eq({
        "apiKeySecurityScheme" => {
          "name"        => "X-API-Key",
          "location"          => "header",
          "description" => "An API key"
        }
      })
    end

    it "includes nil description" do
      scheme = described_class.new(name: "X-API-Key", location: "query")

      expect(scheme.to_h["apiKeySecurityScheme"]["description"]).to be_nil
    end

    it "round-trips through from_h" do
      original = described_class.new(name: "X-API-Key", location: "header")
      restored = described_class.from_h(original.to_h["apiKeySecurityScheme"])

      expect(restored.name).to eq original.name
      expect(restored.location).to eq original.location
    end
  end
end
