# frozen_string_literal: true

module A2A
  module Streaming
    class Response
      PAYLOAD_TYPES = {
        task: Task,
        message: Message,
        status_update: StatusUpdateEvent,
        artifact_update: ArtifactUpdateEvent
      }.freeze

      BUILDERS = {
        "task" => ->(v) { new(:task, Task.from_h(v)) },
        "message" => ->(v) { new(:message, Message.from_h(v)) },
        "statusUpdate" => ->(v) { new(:status_update, StatusUpdateEvent.from_h(v)) },
        "artifactUpdate" => ->(v) { new(:artifact_update, ArtifactUpdateEvent.from_h(v)) }
      }.freeze

      attr_reader :type, :payload

      def initialize(type, payload)
        expected = PAYLOAD_TYPES.fetch(type) { raise ArgumentError, "unknown type: #{type.inspect}" }
        raise TypeError, "payload must be a #{expected}" unless payload.is_a?(expected)

        @type = type
        @payload = payload
      end

      def self.from_h(hash)
        key, builder = BUILDERS.find { |k, _| hash.key?(k) }
        raise ArgumentError, "unrecognised StreamResponse keys: #{hash.keys.inspect}" unless key

        builder.call(hash[key])
      end

      WIRE_KEYS = {
        task: "task",
        message: "message",
        status_update: "statusUpdate",
        artifact_update: "artifactUpdate"
      }.freeze

      def to_h
        { WIRE_KEYS.fetch(type) => payload.to_h }
      end

      def task?
        type == :task
      end

      def message?
        type == :message
      end

      def status_update?
        type == :status_update
      end

      def artifact_update?
        type == :artifact_update
      end
    end
  end
end
