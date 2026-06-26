# frozen_string_literal: true

RSpec.describe A2A::Part::Text do
  describe "#initialize" do
    it "sets text and defaults optional fields" do
      part = described_class.new(text: "Hello World")

      expect(part.text).to eq "Hello World"
      expect(part.media_type).to be_nil
      expect(part.filename).to be_nil
      expect(part.metadata).to be_nil
    end

    it "accepts all optional fields" do
      part = described_class.new(
        text: "Hello World",
        media_type: "text/plain",
        filename: "hello.txt",
        metadata: { "key" => "value" }
      )

      expect(part.media_type).to eq "text/plain"
      expect(part.filename).to eq "hello.txt"
      expect(part.metadata).to eq({ "key" => "value" })
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      part = described_class.from_h("text" => "Hello World")

      expect(part.text).to eq "Hello World"
      expect(part.media_type).to be_nil
      expect(part.filename).to be_nil
      expect(part.metadata).to be_nil
    end

    it "builds from a full hash" do
      part = described_class.from_h(
        "text" => "Hello World",
        "mediaType" => "text/plain",
        "filename" => "hello.txt",
        "metadata" => { "key" => "value" }
      )

      expect(part.text).to eq "Hello World"
      expect(part.media_type).to eq "text/plain"
      expect(part.filename).to eq "hello.txt"
      expect(part.metadata).to eq({ "key" => "value" })
    end
  end

  describe ".from_h unknown keys" do
    it "ignores unrecognized fields" do
      part = described_class.from_h("text" => "hi", "futureKey" => "ignored")
      expect(part.text).to eq "hi"
    end
  end

  describe "#to_h" do
    it "serializes all fields" do
      part = described_class.new(
        text: "Hello World",
        media_type: "text/plain",
        filename: "hello.txt",
        metadata: { "key" => "value" }
      )

      expect(part.to_h).to eq({
        "text" => "Hello World",
        "mediaType" => "text/plain",
        "filename" => "hello.txt",
        "metadata" => { "key" => "value" }
      })
    end

    it "omits nil optional fields" do
      part = described_class.new(text: "Hello World")

      result = part.to_h
      expect(result["text"]).to eq "Hello World"
      expect(result).not_to have_key("mediaType")
      expect(result).not_to have_key("filename")
      expect(result).not_to have_key("metadata")
    end
  end
end
