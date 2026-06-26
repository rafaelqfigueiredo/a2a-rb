# frozen_string_literal: true

module A2A
  module Operation
    class ListTasks
      include Executable

      METHOD = "ListTasks"

      attr_reader :context_id, :status, :page_size, :page_token, :history_length,
                  :status_timestamp_after, :include_artifacts, :tenant

      def initialize(**kwargs)
        @context_id = kwargs[:context_id]
        @status = kwargs[:status]
        @page_size = kwargs[:page_size]
        @page_token = kwargs[:page_token]
        @history_length = kwargs[:history_length]
        @status_timestamp_after = kwargs[:status_timestamp_after]
        @include_artifacts = kwargs[:include_artifacts]
        @tenant = kwargs[:tenant]
      end

      def execute_json_rpc(protocol)
        raw = protocol.post(METHOD, params)
        raise A2A.from_json_rpc_error(raw["error"]) if raw["error"]

        Response.from_h(Hash(raw["result"]))
      end

      def execute_http_json(protocol)
        Response.from_h(protocol.get("/tasks", query: params))
      end

      def params
        {
          "contextId" => context_id,
          "status" => status,
          "pageSize" => page_size,
          "pageToken" => page_token,
          "historyLength" => history_length,
          "statusTimestampAfter" => status_timestamp_after,
          "includeArtifacts" => include_artifacts,
          "tenant" => tenant
        }.compact
      end

      class Response
        attr_reader :tasks, :next_page_token, :page_size, :total_size

        def initialize(tasks:, next_page_token:, page_size:, total_size:)
          @tasks = tasks
          @next_page_token = next_page_token
          @page_size = page_size
          @total_size = total_size
        end

        def self.from_h(hash)
          new(
            tasks: Array(hash["tasks"]).map { Task.from_h(_1) },
            next_page_token: hash.fetch("nextPageToken"),
            page_size: hash.fetch("pageSize"),
            total_size: hash.fetch("totalSize")
          )
        end

        def to_h
          {
            "tasks" => tasks.map(&:to_h),
            "nextPageToken" => next_page_token,
            "pageSize" => page_size,
            "totalSize" => total_size
          }
        end
      end
    end
  end
end
