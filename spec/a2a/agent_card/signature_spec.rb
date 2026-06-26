# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::AgentCard::Signature do
  let(:protected_header) { "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSJ9" }
  let(:signature_value) { "abc123sig" }

  describe ".from_h" do
    it "builds from a full hash" do
      sig = described_class.from_h(
        "protected" => protected_header,
        "signature" => signature_value,
        "header" => { "kid" => "key-1" }
      )

      expect(sig.protected_header).to eq(protected_header)
      expect(sig.signature).to eq(signature_value)
      expect(sig.header).to eq("kid" => "key-1")
    end

    it "builds without the optional header" do
      sig = described_class.from_h(
        "protected" => protected_header,
        "signature" => signature_value
      )

      expect(sig.header).to be_nil
    end

    it "raises KeyError when protected is missing" do
      expect { described_class.from_h("signature" => signature_value) }.to raise_error(KeyError)
    end

    it "raises KeyError when signature is missing" do
      expect { described_class.from_h("protected" => protected_header) }.to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serialises all fields" do
      sig = described_class.new(protected_header: protected_header, signature: signature_value,
                                header: { "kid" => "key-1" })

      expect(sig.to_h).to eq(
        "protected" => protected_header,
        "signature" => signature_value,
        "header" => { "kid" => "key-1" }
      )
    end

    it "omits nil header" do
      sig = described_class.new(protected_header: protected_header, signature: signature_value)

      expect(sig.to_h).not_to have_key("header")
    end

    it "round-trips from_h → to_h" do
      hash = { "protected" => protected_header, "signature" => signature_value }

      expect(described_class.from_h(hash).to_h).to eq(hash)
    end
  end
end
