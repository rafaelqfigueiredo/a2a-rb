# frozen_string_literal: true

require_relative "send_message/configuration"

module A2A
  module Operation
    # Server-side counterpart to SendMessage. Deserialises the params hash from
    # an incoming SendMessage / SendStreamingMessage JSON-RPC call or HTTP+JSON
    # request body into typed objects.
    class SendMessageRequest
      attr_reader :message, :configuration, :metadata, :tenant

      def initialize(message:, configuration: nil, metadata: nil, tenant: nil)
        @message = message
        @configuration = configuration
        @metadata = metadata
        @tenant = tenant
      end

      def self.from_h(hash)
        config_raw = hash["configuration"]
        config = if config_raw
                   SendMessage::Configuration.from_h(config_raw)
                 else
                   SendMessage::Configuration.new
                 end

        new(
          message: Message.from_h(hash.fetch("message")),
          configuration: config,
          metadata: hash["metadata"],
          tenant: hash["tenant"]
        )
      end
    end
  end
end
