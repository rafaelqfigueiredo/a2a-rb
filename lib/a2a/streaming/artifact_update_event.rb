# frozen_string_literal: true

module A2A
  module Streaming
    class ArtifactUpdateEvent
      attr_reader :task_id, :context_id, :artifact, :append, :last_chunk, :metadata

      def initialize(task_id:, context_id:, artifact:, **kwargs)
        @task_id = task_id
        @context_id = context_id
        @artifact = artifact
        @append = kwargs[:append] || false
        @last_chunk = kwargs[:last_chunk] || false
        @metadata = kwargs[:metadata]
      end

      def to_h
        {
          "taskId" => task_id,
          "contextId" => context_id,
          "artifact" => artifact.to_h,
          "append" => append,
          "lastChunk" => last_chunk,
          "metadata" => metadata
        }.compact
      end

      def self.from_h(hash)
        new(
          task_id: hash.fetch("taskId"),
          context_id: hash.fetch("contextId"),
          artifact: Artifact.from_h(hash.fetch("artifact")),
          append: hash["append"],
          last_chunk: hash["lastChunk"],
          metadata: hash["metadata"]
        )
      end
    end
  end
end
