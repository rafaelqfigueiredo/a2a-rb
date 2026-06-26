# frozen_string_literal: true

require "a2a/security_scheme/mutual_tls"

RSpec.describe A2A::SecurityScheme::MutualTLS do
  describe "#initialize" do
    it "defaults description to nil" do
      scheme = described_class.new

      expect(scheme.description).to be_nil
    end

    it "accepts an optional description" do
      scheme = described_class.new(description: "mTLS auth")

      expect(scheme.description).to eq "mTLS auth"
    end
  end

  describe ".from_h" do
    it "builds from an empty hash" do
      scheme = described_class.from_h({})

      expect(scheme.description).to be_nil
    end

    it "builds with a description" do
      scheme = described_class.from_h("description" => "mTLS auth")

      expect(scheme.description).to eq "mTLS auth"
    end
  end

  describe "#to_h" do
    it "serializes under the mtlsSecurityScheme key" do
      scheme = described_class.new(description: "mTLS auth")

      expect(scheme.to_h).to eq({
        "mtlsSecurityScheme" => { "description" => "mTLS auth" }
      })
    end

    it "omits nil description" do
      scheme = described_class.new

      expect(scheme.to_h).to eq({ "mtlsSecurityScheme" => {} })
    end

    it "round-trips through from_h" do
      original = described_class.new(description: "mTLS auth")
      restored = described_class.from_h(original.to_h["mtlsSecurityScheme"])

      expect(restored.description).to eq original.description
    end
  end
end
