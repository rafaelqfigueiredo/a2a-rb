# frozen_string_literal: true

require "a2a"
require "webmock/rspec"

RSpec.describe A2A::Discovery do
  let(:base_url) { "https://agent.example.com" }
  let(:well_known_url) { "#{base_url}/.well-known/agent-card.json" }

  let(:card_hash) do
    {
      "name" => "Test Agent",
      "description" => "A test agent",
      "version" => "1.0",
      "capabilities" => { "streaming" => false, "pushNotifications" => false,
                          "extendedAgentCard" => true },
      "defaultInputModes" => ["text/plain"],
      "defaultOutputModes" => ["text/plain"],
      "skills" => [{ "id" => "s1", "name" => "Skill", "description" => "desc",
                     "tags" => ["general"], "inputModes" => ["text/plain"],
                     "outputModes" => ["text/plain"] }],
      "supportedInterfaces" => [{ "url" => "#{base_url}/rpc",
                                  "protocolBinding" => "JSONRPC",
                                  "protocolVersion" => "1.0" }]
    }
  end

  describe ".fetch" do
    it "GETs /.well-known/a2a and returns an AgentCard" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: card_hash.to_json,
                   headers: { "Content-Type" => "application/json" })

      card = described_class.fetch(base_url)

      expect(card).to be_a(A2A::AgentCard)
      expect(card.name).to eq("Test Agent")
    end

    it "strips trailing slash from base_url" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: card_hash.to_json,
                   headers: { "Content-Type" => "application/json" })

      expect { described_class.fetch("#{base_url}/") }.not_to raise_error
    end

    it "sends Accept: application/json" do
      stub_request(:get, well_known_url)
        .with(headers: { "Accept" => "application/json" })
        .to_return(status: 200, body: card_hash.to_json,
                   headers: { "Content-Type" => "application/json" })

      described_class.fetch(base_url)
    end

    it "raises TransportError on 404" do
      stub_request(:get, well_known_url).to_return(status: 404)

      expect { described_class.fetch(base_url) }
        .to raise_error(A2A::TransportError, /404/)
    end

    it "raises AuthenticationError on 401" do
      stub_request(:get, well_known_url).to_return(status: 401)

      expect { described_class.fetch(base_url) }
        .to raise_error(A2A::AuthenticationError)
    end

    it "raises TransportError on 5xx" do
      stub_request(:get, well_known_url).to_return(status: 503)

      expect { described_class.fetch(base_url) }
        .to raise_error(A2A::TransportError, /503/)
    end

    it "accepts an injectable transport" do
      transport = instance_double(A2A::Discovery::Transport)
      allow(transport).to receive(:get).with(well_known_url).and_return(card_hash)

      card = described_class.fetch(base_url, transport: transport)

      expect(card.name).to eq("Test Agent")
    end
  end

  describe ".fetch_extended" do
    let(:extended_card_hash) { card_hash.merge("name" => "Test Agent Extended") }

    it "fetches the public card then calls GetExtendedAgentCard" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: card_hash.to_json,
                   headers: { "Content-Type" => "application/json" })
      stub_request(:post, "#{base_url}/rpc")
        .to_return(status: 200,
                   body: { "jsonrpc" => "2.0", "id" => "1",
                           "result" => extended_card_hash }.to_json,
                   headers: { "Content-Type" => "application/json" })

      card = described_class.fetch_extended(base_url)

      expect(card).to be_a(A2A::AgentCard)
      expect(card.name).to eq("Test Agent Extended")
    end

    it "forwards headers to the protocol" do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: card_hash.to_json,
                   headers: { "Content-Type" => "application/json" })
      stub_request(:post, "#{base_url}/rpc")
        .with(headers: { "Authorization" => "Bearer tok" })
        .to_return(status: 200,
                   body: { "jsonrpc" => "2.0", "id" => "1",
                           "result" => extended_card_hash }.to_json,
                   headers: { "Content-Type" => "application/json" })

      described_class.fetch_extended(base_url, headers: { "Authorization" => "Bearer tok" })
    end
  end

  describe "WELL_KNOWN_PATH" do
    it "is /.well-known/agent-card.json per §8.2" do
      expect(described_class::WELL_KNOWN_PATH).to eq("/.well-known/agent-card.json")
    end
  end
end
