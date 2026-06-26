# frozen_string_literal: true

module A2A
  module Operation
    class GetExtendedAgentCard
      include Executable

      METHOD = "GetExtendedAgentCard"

      attr_reader :tenant

      def initialize(tenant: nil)
        @tenant = tenant
      end

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        AgentCard.from_h(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        AgentCard.from_h(protocol.get("/extendedAgentCard", query: {}))
      end

      def params
        { "tenant" => tenant }.compact
      end
    end
  end
end
