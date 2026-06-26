# frozen_string_literal: true

module A2A
  module Operation
    class ListTaskPushNotificationConfigs
      include Executable

      METHOD = "ListTaskPushNotificationConfigs"

      attr_reader :task_id, :page_size, :page_token, :tenant

      def initialize(task_id:, page_size: nil, page_token: nil, tenant: nil)
        @task_id = task_id
        @page_size = page_size
        @page_token = page_token
        @tenant = tenant
      end

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        Response.from_h(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        query = { "pageSize" => page_size, "pageToken" => page_token }.compact
        Response.from_h(protocol.get("/tasks/#{task_id}/pushNotificationConfigs", query: query))
      end

      def params
        {
          "taskId" => task_id,
          "pageSize" => page_size,
          "pageToken" => page_token,
          "tenant" => tenant
        }.compact
      end

      class Response
        attr_reader :configs, :next_page_token

        def initialize(configs:, next_page_token: nil)
          @configs = configs
          @next_page_token = next_page_token
        end

        def self.from_h(hash)
          new(
            configs: Array(hash["configs"]).map { PushNotification::Config.from_h(it) },
            next_page_token: hash["nextPageToken"]
          )
        end

        def to_h
          {
            "configs" => configs.map(&:to_h),
            "nextPageToken" => next_page_token
          }.compact
        end
      end
    end
  end
end
