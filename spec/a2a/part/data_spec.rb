# frozen_string_literal: true

RSpec.describe A2A::Part::Data do
  describe "#initialize" do
    it "sets data and defaults optional fields" do
      part = described_class.new(data: { "key" => "value" })

      expect(part.data).to eq({ "key" => "value" })
      expect(part.media_type).to be_nil
      expect(part.filename).to be_nil
      expect(part.metadata).to be_nil
    end

    it "accepts all optional fields" do
      part = described_class.new(
        data: { "key" => "value" },
        media_type: "application/json",
        filename: "data.json",
        metadata: { "tag" => "v1" }
      )

      expect(part.media_type).to eq "application/json"
      expect(part.filename).to eq "data.json"
      expect(part.metadata).to eq({ "tag" => "v1" })
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      part = described_class.from_h("data" => { "key" => "value" })

      expect(part.data).to eq({ "key" => "value" })
      expect(part.media_type).to be_nil
      expect(part.filename).to be_nil
      expect(part.metadata).to be_nil
    end

    it "builds from a full hash" do
      part = described_class.from_h(
        "data" => { "key" => "value" },
        "mediaType" => "application/json",
        "filename" => "data.json",
        "metadata" => { "tag" => "v1" }
      )

      expect(part.data).to eq({ "key" => "value" })
      expect(part.media_type).to eq "application/json"
      expect(part.filename).to eq "data.json"
      expect(part.metadata).to eq({ "tag" => "v1" })
    end
  end

  describe "#to_h" do
    it "serializes all fields" do
      part = described_class.new(
        data: { "key" => "value" },
        media_type: "application/json",
        filename: "data.json",
        metadata: { "tag" => "v1" }
      )

      expect(part.to_h).to eq({
        "data" => { "key" => "value" },
        "mediaType" => "application/json",
        "filename" => "data.json",
        "metadata" => { "tag" => "v1" }
      })
    end

    it "omits nil optional fields" do
      part = described_class.new(data: "Hello World")

      result = part.to_h
      expect(result["data"]).to eq "Hello World"
      expect(result).not_to have_key("mediaType")
      expect(result).not_to have_key("filename")
      expect(result).not_to have_key("metadata")
    end
  end
end
