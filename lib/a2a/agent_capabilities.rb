# frozen_string_literal: true

module A2A
  class AgentCapabilities
    attr_reader :streaming, :push_notifications, :extensions, :extended_agent_card

    def initialize(streaming: nil, push_notifications: nil, extensions: nil, extended_agent_card: nil)
      @streaming = streaming
      @push_notifications = push_notifications
      @extensions = extensions
      @extended_agent_card = extended_agent_card
    end

    def self.from_h(hash)
      new(
        streaming: hash["streaming"],
        push_notifications: hash["pushNotifications"],
        extensions: hash["extensions"]&.map { AgentExtension.from_h(_1) },
        extended_agent_card: hash["extendedAgentCard"]
      )
    end

    def to_h
      {
        "streaming" => streaming,
        "pushNotifications" => push_notifications,
        "extensions" => extensions,
        "extendedAgentCard" => extended_agent_card
      }.compact
    end
  end
end
