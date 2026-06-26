# frozen_string_literal: true

module A2A
  class Task
    module State
      UNSPECIFIED    = "TASK_STATE_UNSPECIFIED"
      SUBMITTED      = "TASK_STATE_SUBMITTED"
      WORKING        = "TASK_STATE_WORKING"
      INPUT_REQUIRED = "TASK_STATE_INPUT_REQUIRED"
      AUTH_REQUIRED  = "TASK_STATE_AUTH_REQUIRED"
      COMPLETED      = "TASK_STATE_COMPLETED"
      FAILED         = "TASK_STATE_FAILED"
      CANCELED       = "TASK_STATE_CANCELED"
      REJECTED       = "TASK_STATE_REJECTED"

      ALL = [UNSPECIFIED, SUBMITTED, WORKING, INPUT_REQUIRED, AUTH_REQUIRED,
             COMPLETED, FAILED, CANCELED, REJECTED].freeze

      TERMINAL  = [COMPLETED, FAILED, CANCELED, REJECTED].freeze
      RESUMABLE = [INPUT_REQUIRED, AUTH_REQUIRED].freeze

      def self.valid?(value)
        ALL.include?(value)
      end

      def self.terminal?(value)
        TERMINAL.include?(value)
      end
    end
  end
end
