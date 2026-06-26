# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::AgentCard::Verifier do
  let(:base_card_args) do
    {
      name: "Agent", description: "desc", version: "1.0",
      supported_interfaces: [
        A2A::AgentInterface.new(url: "https://agent.example.com/rpc",
                                protocol_binding: A2A::AgentInterface::JSONRPC,
                                protocol_version: "1.0")
      ],
      capabilities: A2A::AgentCapabilities.new,
      skills: [A2A::AgentSkill.new(id: "s1", name: "S", description: "d", tags: ["t"],
                                   input_modes: ["text/plain"], output_modes: ["text/plain"])],
      default_input_modes: ["text/plain"],
      default_output_modes: ["text/plain"]
    }
  end

  describe ".verify!" do
    it "returns true for an unsigned card" do
      card = A2A::AgentCard.new(**base_card_args)

      expect(described_class.verify!(card)).to be true
    end

    it "returns true when signatures is an empty array" do
      card = A2A::AgentCard.new(**base_card_args, signatures: [])

      expect(described_class.verify!(card)).to be true
    end

    it "raises NotImplementedError when the card carries signatures" do
      sig = A2A::AgentCard::Signature.new(
        protected_header: "eyJhbGciOiJFUzI1NiJ9",
        signature: "abc123"
      )
      card = A2A::AgentCard.new(**base_card_args, signatures: [sig])

      expect { described_class.verify!(card) }
        .to raise_error(NotImplementedError, /§8.4/)
    end

    it "includes the signature count in the error message" do
      sigs = [
        A2A::AgentCard::Signature.new(protected_header: "a", signature: "b"),
        A2A::AgentCard::Signature.new(protected_header: "c", signature: "d")
      ]
      card = A2A::AgentCard.new(**base_card_args, signatures: sigs)

      expect { described_class.verify!(card) }
        .to raise_error(NotImplementedError, /2 signature/)
    end
  end
end
