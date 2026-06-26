# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::GetExtendedAgentCard do
  def agent_card_hash
    {
      "name" => "Test Agent",
      "description" => "A test agent",
      "version" => "1.0",
      "supportedInterfaces" => [
        { "url" => "https://agent.example.com/rpc", "protocolBinding" => "JSONRPC", "protocolVersion" => "2.0" }
      ],
      "capabilities" => { "streaming" => false, "pushNotifications" => false, "extendedAgentCard" => true },
      "skills" => [{ "id" => "skill-1", "name" => "Test Skill", "description" => "Does things", "tags" => ["general"] }],
      "defaultInputModes" => ["text/plain"],
      "defaultOutputModes" => ["text/plain"]
    }
  end

  def protocol_binding_returning(result)
    double("protocol_binding").tap { |t| allow(t).to receive(:post).and_return({ "result" => result }) }
  end

  describe "#execute" do
    it "returns an AgentCard" do
      result = described_class.new.execute(protocol_binding_returning(agent_card_hash))

      expect(result).to be_a(A2A::AgentCard)
      expect(result.name).to eq("Test Agent")
    end

    it "raises ExtendedAgentCardNotConfiguredError when not configured" do
      pb = double("protocol_binding")
      allow(pb).to receive(:post).and_return(
        { "error" => { "code" => -32007, "message" => "not configured" } }
      )

      expect { described_class.new.execute(pb) }
        .to raise_error(A2A::ExtendedAgentCardNotConfiguredError)
    end
  end

  describe "#params" do
    it "returns empty hash when no tenant" do
      expect(described_class.new.params).to eq({})
    end

    it "includes tenant when provided" do
      expect(described_class.new(tenant: "acme").params).to eq("tenant" => "acme")
    end
  end
end
