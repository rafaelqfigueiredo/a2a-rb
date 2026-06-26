# frozen_string_literal: true

RSpec.describe A2A::Part do
  describe ".from_h" do
    context "when hash has a 'text' key" do
      it "returns a Text part" do
        part = described_class.from_h("text" => "hello")

        expect(part).to be_a(A2A::Part::Text)
        expect(part.text).to eq "hello"
      end
    end

    context "when hash has a 'data' key" do
      it "returns a Data part" do
        part = described_class.from_h("data" => { "score" => 42 })

        expect(part).to be_a(A2A::Part::Data)
        expect(part.data).to eq({ "score" => 42 })
      end
    end

    context "when hash has a 'raw' key" do
      it "returns a File part" do
        part = described_class.from_h("raw" => "abc==", "mediaType" => "image/png")

        expect(part).to be_a(A2A::Part::File)
        expect(part.raw).to eq "abc=="
      end
    end

    context "when hash has a 'url' key" do
      it "returns a File part" do
        part = described_class.from_h("url" => "https://example.com/f.pdf")

        expect(part).to be_a(A2A::Part::File)
        expect(part.url).to eq "https://example.com/f.pdf"
      end
    end

    context "when hash has no recognisable keys" do
      it "raises ArgumentError" do
        expect { described_class.from_h("unknown" => "value") }
          .to raise_error(ArgumentError, /cannot detect Part type/)
      end
    end
  end
end
