# frozen_string_literal: true

module A2A
  module Operation
    class CancelTask
      include Executable

      METHOD = "CancelTask"

      attr_reader :id, :metadata, :tenant

      def initialize(id:, metadata: nil, tenant: nil)
        @id = id
        @metadata = metadata
        @tenant = tenant
      end

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        Task.from_h(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        body = metadata ? { "metadata" => metadata } : {}
        Task.from_h(protocol.post("/tasks/#{id}:cancel", body: body))
      end

      def params
        {
          "id" => id,
          "metadata" => metadata,
          "tenant" => tenant
        }.compact
      end
    end
  end
end
