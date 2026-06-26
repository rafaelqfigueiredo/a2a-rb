# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::AgentCard::Builder do
  def minimal_builder
    described_class.new
      .name("Test Agent")
      .description("A test agent")
      .version("1.0")
      .interface(url: "https://agent.example.com/rpc", protocol_binding: A2A::AgentInterface::JSONRPC,
                 protocol_version: "1.0")
      .capabilities(streaming: true)
      .input_modes("text/plain")
      .output_modes("text/plain")
      .skill(id: "s1", name: "Skill One", description: "does things", tags: ["general"])
  end

  describe "#build" do
    it "returns an AgentCard" do
      expect(minimal_builder.build).to be_a(A2A::AgentCard)
    end

    it "sets name, description, version" do
      card = minimal_builder.build

      expect(card.name).to eq("Test Agent")
      expect(card.description).to eq("A test agent")
      expect(card.version).to eq("1.0")
    end

    it "sets capabilities" do
      card = minimal_builder.build

      expect(card.capabilities.streaming).to eq(true)
    end

    it "sets input and output modes" do
      card = minimal_builder.build

      expect(card.default_input_modes).to eq(["text/plain"])
      expect(card.default_output_modes).to eq(["text/plain"])
    end

    it "accumulates multiple input/output modes" do
      card = minimal_builder.input_modes("application/json").output_modes("application/json").build

      expect(card.default_input_modes).to include("text/plain", "application/json")
    end

    it "accumulates multiple skills" do
      card = minimal_builder
        .skill(id: "s2", name: "Skill Two", description: "more things", tags: ["extra"])
        .build

      expect(card.skills.length).to eq(2)
      expect(card.skills.map(&:id)).to eq(%w[s1 s2])
    end

    it "accumulates multiple interfaces" do
      card = minimal_builder
        .interface(url: "https://agent.example.com/http", protocol_binding: A2A::AgentInterface::HTTP_JSON,
                   protocol_version: "1.0")
        .build

      expect(card.supported_interfaces.length).to eq(2)
    end

    it "sets provider via .provider" do
      card = minimal_builder.provider("Acme Corp", url: "https://acme.example.com").build

      expect(card.provider.organization).to eq("Acme Corp")
    end

    it "sets documentation_url and icon_url" do
      card = minimal_builder.documentation_url("https://docs.example.com").icon_url("https://icon.example.com").build

      expect(card.documentation_url).to eq("https://docs.example.com")
      expect(card.icon_url).to eq("https://icon.example.com")
    end

    it "accepts an AgentCapabilities object directly" do
      caps = A2A::AgentCapabilities.new(streaming: false, push_notifications: true)
      card = minimal_builder.capabilities(caps).build

      expect(card.capabilities.push_notifications).to eq(true)
    end

    it "accepts an AgentSkill object directly" do
      skill = A2A::AgentSkill.new(id: "x", name: "X", description: "desc", tags: ["t"])
      builder = described_class.new
        .name("A").description("B").version("1")
        .interface(url: "https://x.com", protocol_binding: A2A::AgentInterface::JSONRPC, protocol_version: "1.0")
        .capabilities
        .input_modes("text/plain").output_modes("text/plain")
        .skill(skill)

      expect(builder.build.skills.first).to eq(skill)
    end

    it "sets security schemes" do
      scheme = A2A::SecurityScheme::HTTPAuth.new(scheme: "Bearer")
      card = minimal_builder.security_scheme("bearerAuth", scheme).build

      expect(card.security_schemes["bearerAuth"]).to be_a(A2A::SecurityScheme::HTTPAuth)
    end

    it "produces a card that survives a to_h / from_h round-trip" do
      card = minimal_builder.build
      restored = A2A::AgentCard.from_h(card.to_h)

      expect(restored.name).to eq(card.name)
      expect(restored.skills.length).to eq(card.skills.length)
    end
  end
end
