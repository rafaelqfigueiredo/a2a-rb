# frozen_string_literal: true

RSpec.describe A2A::AgentProvider do
  describe "#initialize" do
    it "sets organization and url" do
      provider = described_class.new(organization: "Acme Corp", url: "https://acme.example.com")

      expect(provider.organization).to eq "Acme Corp"
      expect(provider.url).to eq "https://acme.example.com"
    end
  end

  describe ".from_h" do
    it "builds from a full hash" do
      provider = described_class.from_h("organization" => "Acme Corp", "url" => "https://acme.example.com")

      expect(provider.organization).to eq "Acme Corp"
      expect(provider.url).to eq "https://acme.example.com"
    end

    it "raises KeyError when organization is missing" do
      expect { described_class.from_h("url" => "https://acme.example.com") }
        .to raise_error(KeyError)
    end

    it "raises KeyError when url is missing" do
      expect { described_class.from_h("organization" => "Acme Corp") }
        .to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serializes organization and url" do
      provider = described_class.new(organization: "Acme Corp", url: "https://acme.example.com")

      expect(provider.to_h).to eq({ "organization" => "Acme Corp", "url" => "https://acme.example.com" })
    end
  end
end
