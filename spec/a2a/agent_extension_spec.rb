# frozen_string_literal: true

RSpec.describe A2A::AgentExtension do
  describe "#initialize" do
    it "defaults all attributes to nil" do
      ext = described_class.new

      expect(ext.uri).to be_nil
      expect(ext.description).to be_nil
      expect(ext.required).to be_nil
      expect(ext.params).to be_nil
    end

    it "accepts all attributes" do
      ext = described_class.new(
        uri: "https://example.com/ext",
        description: "An extension",
        required: true,
        params: { "key" => "value" }
      )

      expect(ext.uri).to eq "https://example.com/ext"
      expect(ext.description).to eq "An extension"
      expect(ext.required).to be true
      expect(ext.params).to eq({ "key" => "value" })
    end
  end

  describe ".from_h" do
    it "builds from a full hash" do
      ext = described_class.from_h(
        "uri" => "https://example.com/ext",
        "description" => "An extension",
        "required" => true,
        "params" => { "key" => "value" }
      )

      expect(ext.uri).to eq "https://example.com/ext"
      expect(ext.description).to eq "An extension"
      expect(ext.required).to be true
      expect(ext.params).to eq({ "key" => "value" })
    end

    it "builds from an empty hash with all defaults" do
      ext = described_class.from_h({})

      expect(ext.uri).to be_nil
      expect(ext.description).to be_nil
      expect(ext.required).to be_nil
      expect(ext.params).to be_nil
    end
  end

  describe "#to_h" do
    it "serializes all fields" do
      ext = described_class.new(
        uri: "https://example.com/ext",
        description: "An extension",
        required: true,
        params: { "key" => "value" }
      )

      expect(ext.to_h).to eq({
        "uri" => "https://example.com/ext",
        "description" => "An extension",
        "required" => true,
        "params" => { "key" => "value" }
      })
    end

    it "omits nil fields when not provided" do
      ext = described_class.new

      result = ext.to_h
      expect(result).not_to have_key("uri")
      expect(result).not_to have_key("description")
      expect(result).not_to have_key("required")
      expect(result).not_to have_key("params")
    end

    it "round-trips through from_h" do
      original = described_class.new(uri: "https://example.com/ext", required: true)
      restored = described_class.from_h(original.to_h)

      expect(restored.uri).to eq original.uri
      expect(restored.required).to eq original.required
    end
  end
end
