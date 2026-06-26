# frozen_string_literal: true

module A2A
  module Operation
    class SendStreamingMessage
      include Executable

      METHOD = "SendStreamingMessage"

      Configuration = SendMessage::Configuration

      attr_reader :message, :configuration, :metadata, :tenant

      def initialize(message, configuration: {}, metadata: nil, tenant: nil)
        @message = message.is_a?(Message) ? message : Message.from_h(message)
        @configuration = if configuration.is_a?(Configuration)
                           configuration
                         else
                           Configuration.new(**configuration.transform_keys(&:to_sym))
                         end
        @metadata = metadata
        @tenant = tenant
      end

      def execute_json_rpc(protocol, &block)
        protocol.stream(METHOD, params) do |response|
          sub = Streaming::Subscription.new(response)
          return sub unless block

          sub.each(&block)
        end
      end

      def execute_http_json(protocol, &block)
        protocol.stream("/message:stream", method: :post, body: params) do |response|
          sub = Streaming::Subscription.new(response)
          return sub unless block

          sub.each(&block)
        end
      end

      def params
        p = { "message" => message.to_h }
        config_h = configuration.to_h
        p["configuration"] = config_h unless config_h.empty?
        p["metadata"] = metadata if metadata
        p["tenant"] = tenant if tenant
        p
      end
    end
  end
end
