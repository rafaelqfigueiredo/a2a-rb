# frozen_string_literal: true

module A2A
  module Operation
    class GetTask
      include Executable

      METHOD = "GetTask"

      attr_reader :id, :history_length, :tenant

      def initialize(id:, history_length: nil, tenant: nil)
        @id = id
        @history_length = history_length
        @tenant = tenant
      end

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        Task.from_h(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        query = { "historyLength" => history_length }.compact
        Task.from_h(protocol.get("/tasks/#{id}", query: query))
      end

      def params
        {
          "id" => id,
          "historyLength" => history_length,
          "tenant" => tenant
        }.compact
      end
    end
  end
end
