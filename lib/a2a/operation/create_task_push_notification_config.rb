# frozen_string_literal: true

module A2A
  module Operation
    class CreateTaskPushNotificationConfig
      include Executable

      METHOD = "CreateTaskPushNotificationConfig"

      attr_reader :config, :tenant

      def initialize(config, tenant: nil)
        @config = config.is_a?(PushNotification::Config) ? config : PushNotification::Config.from_h(config)
        @tenant = tenant
      end

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        PushNotification::Config.from_h(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        PushNotification::Config.from_h(
          protocol.post("/tasks/#{config.task_id}/pushNotificationConfigs", body: config.to_h)
        )
      end

      def params
        {
          "pushNotificationConfig" => config.to_h,
          "tenant" => tenant
        }.compact
      end
    end
  end
end
