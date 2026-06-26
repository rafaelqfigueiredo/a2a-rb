# frozen_string_literal: true

require_relative "send_message/configuration"

module A2A
  module Operation
    class SendMessage
      include Executable

      METHOD = "SendMessage"

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

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        parse_result(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        parse_result(protocol.post("/message:send", body: params))
      end

      def params
        p = { "message" => message.to_h }
        config_h = configuration.to_h
        p["configuration"] = config_h unless config_h.empty?
        p["metadata"] = metadata if metadata
        p["tenant"] = tenant if tenant
        p
      end

      private

      def parse_result(result)
        if result.key?("task")
          Task.from_h(result["task"])
        elsif result.key?("message")
          Message.from_h(result["message"])
        else
          raise InvalidAgentResponseError, "response is neither Task nor Message"
        end
      end
    end
  end
end
