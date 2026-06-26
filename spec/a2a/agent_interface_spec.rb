# frozen_string_literal: true

RSpec.describe A2A::AgentInterface do
  describe "#initialize" do
    it "sets all required attributes" do
      interface = described_class.new(
        url:              "https://agent.example.com/rpc",
        protocol_binding: "JSONRPC",
        protocol_version: "2.0"
      )

      expect(interface.url).to eq "https://agent.example.com/rpc"
      expect(interface.protocol_binding).to eq "JSONRPC"
      expect(interface.protocol_version).to eq "2.0"
    end

    it "defaults tenant to nil" do
      interface = described_class.new(
        url:              "https://agent.example.com/rpc",
        protocol_binding: "JSONRPC",
        protocol_version: "2.0"
      )

      expect(interface.tenant).to be_nil
    end

    it "accepts an optional tenant" do
      interface = described_class.new(
        url:              "https://agent.example.com/rpc",
        protocol_binding: "HTTP+JSON",
        protocol_version: "1.0",
        tenant:           "acme"
      )

      expect(interface.tenant).to eq "acme"
    end

    it "raises ArgumentError for an unknown protocol_binding" do
      expect do
        described_class.new(url: "https://example.com", protocol_binding: "SOAP", protocol_version: "1.0")
      end.to raise_error(ArgumentError, /protocol_binding must be one of/)
    end

    it "accepts JSONRPC as a valid protocol_binding" do
      expect do
        described_class.new(url: "https://example.com", protocol_binding: "JSONRPC", protocol_version: "2.0")
      end.not_to raise_error
    end

    it "accepts GRPC as a valid protocol_binding" do
      expect do
        described_class.new(url: "https://example.com", protocol_binding: "GRPC", protocol_version: "1.0")
      end.not_to raise_error
    end

    it "accepts HTTP+JSON as a valid protocol_binding" do
      expect do
        described_class.new(url: "https://example.com", protocol_binding: "HTTP+JSON", protocol_version: "1.0")
      end.not_to raise_error
    end
  end

  describe ".from_h" do
    it "builds from a full hash" do
      interface = described_class.from_h(
        "url"             => "https://agent.example.com/rpc",
        "protocolBinding" => "JSONRPC",
        "protocolVersion" => "2.0",
        "tenant"          => "acme"
      )

      expect(interface.url).to eq "https://agent.example.com/rpc"
      expect(interface.protocol_binding).to eq "JSONRPC"
      expect(interface.protocol_version).to eq "2.0"
      expect(interface.tenant).to eq "acme"
    end

    it "builds without tenant" do
      interface = described_class.from_h(
        "url"             => "https://agent.example.com/rpc",
        "protocolBinding" => "HTTP+JSON",
        "protocolVersion" => "1.0"
      )

      expect(interface.tenant).to be_nil
    end

    it "raises KeyError when url is missing" do
      expect { described_class.from_h("protocolBinding" => "JSONRPC", "protocolVersion" => "2.0") }
        .to raise_error(KeyError)
    end

    it "raises KeyError when protocolBinding is missing" do
      expect { described_class.from_h("url" => "https://example.com", "protocolVersion" => "2.0") }
        .to raise_error(KeyError)
    end

    it "raises KeyError when protocolVersion is missing" do
      expect { described_class.from_h("url" => "https://example.com", "protocolBinding" => "JSONRPC") }
        .to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serializes all fields with protocol key names" do
      interface = described_class.new(
        url:              "https://agent.example.com/rpc",
        protocol_binding: "JSONRPC",
        protocol_version: "2.0",
        tenant:           "acme"
      )

      expect(interface.to_h).to eq({
        "url"             => "https://agent.example.com/rpc",
        "protocolBinding" => "JSONRPC",
        "protocolVersion" => "2.0",
        "tenant"          => "acme"
      })
    end

    it "includes nil tenant" do
      interface = described_class.new(
        url:              "https://agent.example.com/rpc",
        protocol_binding: "JSONRPC",
        protocol_version: "2.0"
      )

      expect(interface.to_h["tenant"]).to be_nil
    end
  end

  describe "predicate methods" do
    it "#json_rpc? is true for JSONRPC binding" do
      interface = described_class.new(url: "https://x.com", protocol_binding: "JSONRPC", protocol_version: "2.0")

      expect(interface.json_rpc?).to be true
      expect(interface.grpc?).to be false
      expect(interface.http_json?).to be false
    end

    it "#grpc? is true for GRPC binding" do
      interface = described_class.new(url: "https://x.com", protocol_binding: "GRPC", protocol_version: "1.0")

      expect(interface.grpc?).to be true
      expect(interface.json_rpc?).to be false
      expect(interface.http_json?).to be false
    end

    it "#http_json? is true for HTTP+JSON binding" do
      interface = described_class.new(url: "https://x.com", protocol_binding: "HTTP+JSON", protocol_version: "1.0")

      expect(interface.http_json?).to be true
      expect(interface.json_rpc?).to be false
      expect(interface.grpc?).to be false
    end
  end
end
