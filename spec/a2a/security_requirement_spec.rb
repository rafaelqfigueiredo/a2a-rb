# frozen_string_literal: true

RSpec.describe A2A::SecurityRequirement do
  describe "#initialize" do
    it "sets schemes" do
      req = described_class.new(schemes: { "bearer" => ["read", "write"] })

      expect(req.schemes).to eq({ "bearer" => ["read", "write"] })
    end

    it "accepts an empty schemes hash" do
      req = described_class.new(schemes: {})

      expect(req.schemes).to eq({})
    end

    it "accepts multiple schemes" do
      req = described_class.new(schemes: { "bearer" => ["read"], "apiKey" => [] })

      expect(req.schemes.keys).to contain_exactly("bearer", "apiKey")
    end
  end

  describe ".from_h" do
    it "builds from a flat scopes array" do
      req = described_class.from_h("bearer" => ["read", "write"])

      expect(req.schemes).to eq({ "bearer" => ["read", "write"] })
    end

    it "builds from an empty hash" do
      req = described_class.from_h({})

      expect(req.schemes).to eq({})
    end

    it "builds with multiple schemes" do
      req = described_class.from_h("bearer" => ["read"], "apiKey" => [])

      expect(req.schemes).to eq({ "bearer" => ["read"], "apiKey" => [] })
    end
  end

  describe "#to_h" do
    it "serializes schemes as the hash itself" do
      req = described_class.new(schemes: { "bearer" => ["read"] })

      expect(req.to_h).to eq({ "bearer" => ["read"] })
    end

    it "round-trips through from_h" do
      original = described_class.new(schemes: { "bearer" => ["read", "write"] })
      restored = described_class.from_h(original.to_h)

      expect(restored.schemes).to eq original.schemes
    end
  end
end
