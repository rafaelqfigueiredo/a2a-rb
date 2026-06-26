# frozen_string_literal: true

module A2A
  module Streaming
    # The `final` field is a gem-level streaming-termination hint, not in the A2A proto.
    # Servers that set "final": true signal this is the last status event for the task.
    class StatusUpdateEvent
      attr_reader :task_id, :context_id, :status, :final, :metadata

      def initialize(context_id:, task_id:, status:, **kwargs)
        raise TypeError, "status must be a Task::Status" unless status.is_a?(Task::Status)

        @context_id = context_id
        @task_id = task_id
        @status = status
        @final = kwargs.fetch(:final, false)
        @metadata = kwargs[:metadata]
      end

      def final? = @final

      def to_h
        {
          "taskId" => task_id,
          "contextId" => context_id,
          "status" => status.to_h,
          "final" => final,
          "metadata" => metadata
        }.compact
      end

      def self.from_h(hash)
        new(
          task_id: hash.fetch("taskId"),
          context_id: hash.fetch("contextId"),
          status: Task::Status.from_h(hash.fetch("status")),
          final: hash.fetch("final", false),
          metadata: hash["metadata"]
        )
      end
    end
  end
end
