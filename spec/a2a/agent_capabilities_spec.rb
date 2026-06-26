# frozen_string_literal: true

RSpec.describe A2A::AgentCapabilities do
  describe "#initialize" do
    it "defaults all capabilities to nil" do
      caps = described_class.new

      expect(caps.streaming).to be_nil
      expect(caps.push_notifications).to be_nil
      expect(caps.extensions).to be_nil
      expect(caps.extended_agent_card).to be_nil
    end

    it "accepts streaming: true" do
      caps = described_class.new(streaming: true)

      expect(caps.streaming).to be true
      expect(caps.push_notifications).to be_nil
    end

    it "accepts push_notifications: true" do
      caps = described_class.new(push_notifications: true)

      expect(caps.push_notifications).to be true
      expect(caps.streaming).to be_nil
    end

    it "accepts extended_agent_card: true" do
      caps = described_class.new(extended_agent_card: true)

      expect(caps.extended_agent_card).to be true
    end

    it "accepts a list of extensions" do
      caps = described_class.new(extensions: [{ "uri" => "https://example.com/ext" }])

      expect(caps.extensions).to eq [{ "uri" => "https://example.com/ext" }]
    end

    it "accepts all capabilities at once" do
      caps = described_class.new(
        streaming: true,
        push_notifications: true,
        extensions: [{ "uri" => "https://example.com/ext" }],
        extended_agent_card: true
      )

      expect(caps.streaming).to be true
      expect(caps.push_notifications).to be true
      expect(caps.extensions).to eq [{ "uri" => "https://example.com/ext" }]
      expect(caps.extended_agent_card).to be true
    end
  end

  describe ".from_h" do
    it "builds from an empty hash with all defaults" do
      caps = described_class.from_h({})

      expect(caps.streaming).to be_nil
      expect(caps.push_notifications).to be_nil
      expect(caps.extensions).to be_nil
      expect(caps.extended_agent_card).to be_nil
    end

    it "deserializes all fields" do
      caps = described_class.from_h(
        "streaming" => true,
        "pushNotifications" => true,
        "extensions" => [{ "uri" => "https://example.com/ext" }],
        "extendedAgentCard" => true
      )

      expect(caps.streaming).to be true
      expect(caps.push_notifications).to be true
      expect(caps.extensions.first).to be_a(A2A::AgentExtension)
      expect(caps.extensions.first.uri).to eq "https://example.com/ext"
      expect(caps.extended_agent_card).to be true
    end

    it "deserializes a partial hash" do
      caps = described_class.from_h("streaming" => true)

      expect(caps.streaming).to be true
      expect(caps.push_notifications).to be_nil
      expect(caps.extensions).to be_nil
      expect(caps.extended_agent_card).to be_nil
    end
  end

  describe "#to_h" do
    it "omits all nil capabilities" do
      expect(described_class.new.to_h).to eq({})
    end

    it "serializes true capabilities" do
      caps = described_class.new(
        streaming: true,
        push_notifications: true,
        extensions: [{ "uri" => "https://example.com/ext" }],
        extended_agent_card: true
      )

      expect(caps.to_h).to eq({
        "streaming" => true,
        "pushNotifications" => true,
        "extensions" => [{ "uri" => "https://example.com/ext" }],
        "extendedAgentCard" => true
      })
    end

    it "round-trips through from_h" do
      caps = described_class.new(streaming: true, extended_agent_card: true)
      restored = described_class.from_h(caps.to_h)

      expect(restored.streaming).to be true
      expect(restored.extended_agent_card).to be true
      expect(restored.push_notifications).to be_nil
    end
  end
end
