# frozen_string_literal: true

module A2A
  class Task
    class Status
      attr_reader :state, :message, :timestamp

      def initialize(state:, message: nil, timestamp: nil)
        @state = state
        @message = message
        @timestamp = timestamp
      end

      def self.from_h(hash)
        new(
          state: hash.fetch("state"),
          message: hash["message"] && Message.from_h(hash["message"]),
          timestamp: hash["timestamp"]
        )
      end

      def to_h
        {
          "state" => state,
          "message" => message&.to_h,
          "timestamp" => timestamp
        }.compact
      end

      def terminal?
        Task::State.terminal?(state)
      end
    end
  end
end
