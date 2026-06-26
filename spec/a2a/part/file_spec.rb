# frozen_string_literal: true

RSpec.describe A2A::Part::File do
  describe "#initialize" do
    it "sets all attributes" do
      part = described_class.new(raw: "abc==", media_type: "image/png", filename: "photo.png",
                                 metadata: { "source" => "upload" })

      expect(part.raw).to eq "abc=="
      expect(part.media_type).to eq "image/png"
      expect(part.filename).to eq "photo.png"
      expect(part.metadata).to eq({ "source" => "upload" })
    end

    it "defaults all attributes to nil" do
      part = described_class.new

      expect(part.raw).to be_nil
      expect(part.url).to be_nil
      expect(part.filename).to be_nil
      expect(part.media_type).to be_nil
      expect(part.metadata).to be_nil
    end
  end

  describe ".from_h" do
    context "with inline bytes" do
      it "builds a part with raw bytes" do
        part = described_class.from_h(
          "raw" => "base64data==",
          "mediaType" => "image/png",
          "filename" => "photo.png"
        )

        expect(part.raw).to eq "base64data=="
        expect(part.media_type).to eq "image/png"
        expect(part.filename).to eq "photo.png"
        expect(part.metadata).to be_nil
      end
    end

    context "with a remote url" do
      it "builds a part with url" do
        part = described_class.from_h(
          "url" => "https://example.com/file.pdf",
          "mediaType" => "application/pdf"
        )

        expect(part.url).to eq "https://example.com/file.pdf"
        expect(part.raw).to be_nil
      end
    end

    context "with metadata" do
      it "sets metadata on the part" do
        part = described_class.from_h(
          "raw" => "abc==",
          "metadata" => { "tag" => "important" }
        )

        expect(part.metadata).to eq({ "tag" => "important" })
      end
    end
  end

  describe "#to_h" do
    it "serializes all fields" do
      part = described_class.new(
        raw: "abc==",
        filename: "doc.pdf",
        media_type: "application/pdf",
        metadata: { "tag" => "v1" }
      )

      result = part.to_h
      expect(result["raw"]).to eq "abc=="
      expect(result["filename"]).to eq "doc.pdf"
      expect(result["mediaType"]).to eq "application/pdf"
      expect(result["metadata"]).to eq({ "tag" => "v1" })
    end

    it "omits nil fields" do
      part = described_class.new(url: "https://example.com/f.txt")

      result = part.to_h
      expect(result["url"]).to eq "https://example.com/f.txt"
      expect(result).not_to have_key("raw")
      expect(result).not_to have_key("filename")
      expect(result).not_to have_key("metadata")
    end

    it "round-trips through from_h" do
      hash = { "raw" => "abc==", "mediaType" => "image/png", "filename" => "photo.png" }

      expect(described_class.from_h(hash).to_h).to eq hash
    end
  end

  describe "#inline?" do
    it "returns true when raw is present" do
      expect(described_class.new(raw: "abc==").inline?).to be true
    end

    it "returns false when raw is nil" do
      expect(described_class.new(url: "https://example.com/f").inline?).to be false
    end
  end

  describe "#remote?" do
    it "returns true when url is present" do
      expect(described_class.new(url: "https://example.com/f").remote?).to be true
    end

    it "returns false when url is nil" do
      expect(described_class.new(raw: "abc==").remote?).to be false
    end
  end
end
