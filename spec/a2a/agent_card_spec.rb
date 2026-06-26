# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::AgentCard do
  let(:interface_hash) do
    { "url" => "https://example.com/a2a", "protocolBinding" => "JSONRPC", "protocolVersion" => "1.0" }
  end
  let(:capabilities_hash) { { "streaming" => false, "pushNotifications" => false } }
  let(:skill_hash) do
    { "id" => "skill-1", "name" => "My Skill", "description" => "Does things", "tags" => ["general"] }
  end
  let(:minimal_hash) do
    {
      "name" => "My Agent",
      "description" => "An agent",
      "version" => "1.0.0",
      "supportedInterfaces" => [interface_hash],
      "capabilities" => capabilities_hash,
      "skills" => [skill_hash],
      "defaultInputModes" => ["text/plain"],
      "defaultOutputModes" => ["text/plain"]
    }
  end

  let(:interface) { A2A::AgentInterface.from_h(interface_hash) }
  let(:capabilities) { A2A::AgentCapabilities.from_h(capabilities_hash) }
  let(:skill) { A2A::AgentSkill.from_h(skill_hash) }

  describe "#initialize" do
    it "sets required attributes" do
      card = described_class.new(
        name: "My Agent",
        description: "An agent",
        version: "1.0.0",
        supported_interfaces: [interface],
        capabilities: capabilities,
        skills: [skill],
        default_input_modes: ["text/plain"],
        default_output_modes: ["text/plain"]
      )

      expect(card.name).to eq "My Agent"
      expect(card.description).to eq "An agent"
      expect(card.version).to eq "1.0.0"
      expect(card.supported_interfaces).to eq [interface]
      expect(card.capabilities).to eq capabilities
      expect(card.skills).to eq [skill]
      expect(card.default_input_modes).to eq ["text/plain"]
      expect(card.default_output_modes).to eq ["text/plain"]
    end

    it "defaults optional attributes" do
      card = described_class.new(
        name: "My Agent",
        description: "An agent",
        version: "1.0.0",
        supported_interfaces: [interface],
        capabilities: capabilities,
        skills: [skill],
        default_input_modes: ["text/plain"],
        default_output_modes: ["text/plain"]
      )

      expect(card.provider).to be_nil
      expect(card.documentation_url).to be_nil
      expect(card.security_schemes).to be_nil
      expect(card.security_requirements).to be_nil
      expect(card.signatures).to be_nil
      expect(card.icon_url).to be_nil
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      card = described_class.from_h(minimal_hash)

      expect(card.name).to eq "My Agent"
      expect(card.description).to eq "An agent"
      expect(card.version).to eq "1.0.0"
      expect(card.supported_interfaces.first).to be_a(A2A::AgentInterface)
      expect(card.capabilities).to be_a(A2A::AgentCapabilities)
      expect(card.skills.first).to be_a(A2A::AgentSkill)
      expect(card.default_input_modes).to eq ["text/plain"]
      expect(card.default_output_modes).to eq ["text/plain"]
    end

    it "defaults optional fields when absent" do
      card = described_class.from_h(minimal_hash)

      expect(card.provider).to be_nil
      expect(card.documentation_url).to be_nil
      expect(card.security_schemes).to eq({})
      expect(card.security_requirements).to be_nil
      expect(card.signatures).to be_nil
      expect(card.icon_url).to be_nil
    end

    it "builds provider when present" do
      hash = minimal_hash.merge("provider" => { "organization" => "Acme", "url" => "https://acme.com" })
      card = described_class.from_h(hash)

      expect(card.provider).to be_a(A2A::AgentProvider)
      expect(card.provider.organization).to eq "Acme"
    end

    it "deserializes security_schemes" do
      hash = minimal_hash.merge(
        "securitySchemes" => {
          "bearer" => { "httpAuthSecurityScheme" => { "scheme" => "Bearer" } }
        }
      )
      card = described_class.from_h(hash)

      expect(card.security_schemes["bearer"]).to be_a(A2A::SecurityScheme::HTTPAuth)
    end

    it "raises KeyError when name is missing" do
      expect { described_class.from_h(minimal_hash.except("name")) }.to raise_error(KeyError)
    end

    it "raises KeyError when version is missing" do
      expect { described_class.from_h(minimal_hash.except("version")) }.to raise_error(KeyError)
    end

    it "raises KeyError when supportedInterfaces is missing" do
      expect { described_class.from_h(minimal_hash.except("supportedInterfaces")) }.to raise_error(KeyError)
    end

    it "raises KeyError when capabilities is missing" do
      expect { described_class.from_h(minimal_hash.except("capabilities")) }.to raise_error(KeyError)
    end

    it "raises KeyError when skills is missing" do
      expect { described_class.from_h(minimal_hash.except("skills")) }.to raise_error(KeyError)
    end

    it "deserialises signatures as AgentCard::Signature objects" do
      hash = minimal_hash.merge(
        "signatures" => [{ "protected" => "eyJhbGciOiJFUzI1NiJ9", "signature" => "abc123" }]
      )
      card = described_class.from_h(hash)

      expect(card.signatures.length).to eq(1)
      expect(card.signatures.first).to be_a(A2A::AgentCard::Signature)
      expect(card.signatures.first.signature).to eq("abc123")
    end
  end

  describe "#to_h" do
    it "round-trips through from_h" do
      card = described_class.from_h(minimal_hash)

      expect(described_class.from_h(card.to_h).name).to eq(card.name)
    end

    it "omits nil optional fields" do
      card = described_class.from_h(minimal_hash)
      h = card.to_h

      expect(h).not_to have_key("provider")
      expect(h).not_to have_key("documentationUrl")
      expect(h).not_to have_key("signatures")
    end

    it "serialises signatures when present" do
      hash = minimal_hash.merge(
        "signatures" => [{ "protected" => "eyJhbGciOiJFUzI1NiJ9", "signature" => "abc123" }]
      )
      card = described_class.from_h(hash)

      expect(card.to_h["signatures"].first).to eq(
        "protected" => "eyJhbGciOiJFUzI1NiJ9", "signature" => "abc123"
      )
    end
  end

  describe "#canonical_json" do
    it "returns valid JSON" do
      card = described_class.from_h(minimal_hash)

      expect { JSON.parse(card.canonical_json) }.not_to raise_error
    end

    it "excludes the signatures field" do
      hash = minimal_hash.merge(
        "signatures" => [{ "protected" => "eyJhbGciOiJFUzI1NiJ9", "signature" => "abc123" }]
      )
      card = described_class.from_h(hash)

      expect(JSON.parse(card.canonical_json)).not_to have_key("signatures")
    end

    it "sorts keys lexicographically at the top level" do
      card = described_class.from_h(minimal_hash)
      keys = JSON.parse(card.canonical_json).keys

      expect(keys).to eq(keys.sort)
    end

    it "produces the same output for identical cards" do
      card_a = described_class.from_h(minimal_hash)
      card_b = described_class.from_h(minimal_hash)

      expect(card_a.canonical_json).to eq(card_b.canonical_json)
    end
  end
end
