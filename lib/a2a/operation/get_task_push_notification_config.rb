# frozen_string_literal: true

module A2A
  module Operation
    class GetTaskPushNotificationConfig
      include Executable

      METHOD = "GetTaskPushNotificationConfig"

      attr_reader :task_id, :id, :tenant

      def initialize(task_id:, id:, tenant: nil)
        @task_id = task_id
        @id = id
        @tenant = tenant
      end

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        PushNotification::Config.from_h(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        PushNotification::Config.from_h(protocol.get("/tasks/#{task_id}/pushNotificationConfigs/#{id}", query: {}))
      end

      def params
        {
          "taskId" => task_id,
          "id" => id,
          "tenant" => tenant
        }.compact
      end
    end
  end
end
