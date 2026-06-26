# frozen_string_literal: true

RSpec.describe A2A::Artifact do
  let(:text_part) { A2A::Part::Text.new(text: "result") }

  describe "#initialize" do
    it "sets required attributes" do
      artifact = described_class.new(id: "a1", parts: [text_part])

      expect(artifact.id).to eq "a1"
      expect(artifact.parts).to eq [text_part]
    end

    it "raises ArgumentError when parts is empty" do
      expect { described_class.new(id: "a1", parts: []) }
        .to raise_error(ArgumentError, /parts must contain at least one element/)
    end

    it "defaults optional attributes" do
      artifact = described_class.new(id: "a1", parts: [text_part])

      expect(artifact.name).to be_nil
      expect(artifact.description).to be_nil
      expect(artifact.extensions).to be_nil
      expect(artifact.metadata).to be_nil
    end

    it "accepts all optional attributes" do
      artifact = described_class.new(
        id: "a1",
        parts: [text_part],
        name: "report",
        description: "monthly report",
        extensions: ["https://example.com/ext"],
        metadata: { "k" => "v" }
      )

      expect(artifact.name).to eq "report"
      expect(artifact.description).to eq "monthly report"
      expect(artifact.extensions).to eq ["https://example.com/ext"]
      expect(artifact.metadata).to eq({ "k" => "v" })
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      artifact = described_class.from_h(
        "artifactId" => "a1",
        "parts" => [{ "text" => "result" }]
      )

      expect(artifact.id).to eq "a1"
      expect(artifact.parts.first).to be_a(A2A::Part::Text)
      expect(artifact.parts.first.text).to eq "result"
    end

    it "builds from a full hash" do
      artifact = described_class.from_h(
        "artifactId" => "a1",
        "parts" => [{ "text" => "result" }],
        "name" => "report",
        "description" => "monthly report",
        "extensions" => ["https://example.com/ext"],
        "metadata" => { "k" => "v" }
      )

      expect(artifact.name).to eq "report"
      expect(artifact.description).to eq "monthly report"
      expect(artifact.extensions).to eq ["https://example.com/ext"]
      expect(artifact.metadata).to eq({ "k" => "v" })
    end

    it "raises ArgumentError when parts is empty" do
      expect { described_class.from_h("artifactId" => "a1", "parts" => []) }
        .to raise_error(ArgumentError, /parts must contain at least one element/)
    end

    it "raises KeyError when artifactId is missing" do
      expect { described_class.from_h("parts" => [{ "text" => "result" }]) }
        .to raise_error(KeyError)
    end
  end

  describe ".from_h unknown keys" do
    it "ignores unrecognized fields" do
      artifact = described_class.from_h(
        "artifactId" => "a1",
        "parts" => [{ "text" => "result" }],
        "futureField" => "ignored"
      )
      expect(artifact.id).to eq "a1"
    end
  end

  describe "#to_h" do
    it "serializes parts and id" do
      artifact = described_class.new(id: "a1", parts: [text_part])

      result = artifact.to_h
      expect(result["artifactId"]).to eq "a1"
      expect(result["parts"].first["text"]).to eq "result"
    end

    it "includes optional fields when present" do
      artifact = described_class.new(
        id: "a1",
        parts: [text_part],
        name: "report",
        description: "monthly report",
        extensions: ["https://example.com/ext"],
        metadata: { "k" => "v" }
      )

      result = artifact.to_h
      expect(result["name"]).to eq "report"
      expect(result["description"]).to eq "monthly report"
      expect(result["extensions"]).to eq ["https://example.com/ext"]
      expect(result["metadata"]).to eq({ "k" => "v" })
    end

    it "omits nil optional fields" do
      artifact = described_class.new(id: "a1", parts: [text_part])

      result = artifact.to_h
      expect(result).not_to have_key("name")
      expect(result).not_to have_key("description")
      expect(result).not_to have_key("extensions")
      expect(result).not_to have_key("metadata")
    end

    it "round-trips through from_h" do
      original = described_class.new(id: "a1", parts: [text_part], name: "report")
      restored = described_class.from_h(original.to_h)

      expect(restored.id).to eq original.id
      expect(restored.name).to eq original.name
      expect(restored.parts.first.text).to eq "result"
    end
  end
end
