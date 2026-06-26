# frozen_string_literal: true

require_relative "task/state"
require_relative "task/status"

module A2A
  class Task
    attr_reader :id, :context_id, :status, :artifacts, :history, :metadata

    def initialize(id:, status:, **kwargs)
      raise TypeError, "status must be a Task::Status" unless status.is_a?(Task::Status)

      @id = id
      @status = status
      @context_id = kwargs[:context_id]
      @artifacts = kwargs[:artifacts]
      @history = kwargs[:history]
      @metadata = kwargs[:metadata]
    end

    def self.from_h(hash)
      new(
        id: hash.fetch("id"),
        context_id: hash["contextId"],
        status: Task::Status.from_h(hash.fetch("status")),
        artifacts: Array(hash["artifacts"]).map { Artifact.from_h(it) },
        history: Array(hash["history"]).map { Message.from_h(it) },
        metadata: hash["metadata"]
      )
    end

    def terminal?
      status.terminal?
    end

    # Returns a new Task with the status transitioned to `state`.
    # Optionally attaches a status message and ISO-8601 timestamp.
    # Raises ArgumentError for unknown states; raises TaskNotCancelableError
    # when trying to transition away from a terminal state.
    def transition_to(state, message: nil, timestamp: nil)
      raise ArgumentError, "unknown state: #{state.inspect}" unless Task::State.valid?(state)
      raise TaskNotCancelableError, "task #{id} is already in terminal state #{status.state}" if terminal?

      new_status = Task::Status.new(state: state, message: message, timestamp: timestamp)
      Task.new(
        id: id,
        context_id: context_id,
        status: new_status,
        artifacts: artifacts,
        history: history,
        metadata: metadata
      )
    end

    def to_h
      {
        "id" => id,
        "contextId" => context_id,
        "status" => status.to_h,
        "artifacts" => artifacts&.map(&:to_h),
        "history" => history&.map(&:to_h),
        "metadata" => metadata
      }.compact
    end
  end
end
