# frozen_string_literal: true

module A2A
  class Message
    attr_reader :id, :role, :parts,
                :context_id, :task_id,
                :reference_task_ids, :extensions, :metadata

    def initialize(id:, role:, parts:, **kwargs)
      raise ArgumentError, "invalid role: #{role.inspect}" unless Role.valid?(role)
      raise ArgumentError, "parts must contain at least one element" if Array(parts).empty?

      @id = id
      @role = role
      @parts = parts
      @context_id = kwargs[:context_id]
      @task_id = kwargs[:task_id]
      @reference_task_ids = kwargs[:reference_task_ids]
      @extensions = kwargs[:extensions]
      @metadata = kwargs[:metadata]
    end

    def self.from_h(hash)
      new(
        id: hash.fetch("messageId"),
        role: hash.fetch("role"),
        parts: Array(hash["parts"]).map { Part.from_h(_1) },
        context_id: hash["contextId"],
        task_id: hash["taskId"],
        reference_task_ids: hash["referenceTaskIds"],
        extensions: hash["extensions"],
        metadata: hash["metadata"]
      )
    end

    def to_h
      {
        "messageId" => id,
        "role" => role,
        "parts" => parts.map(&:to_h),
        "contextId" => context_id,
        "taskId" => task_id,
        "metadata" => metadata,
        "referenceTaskIds" => reference_task_ids,
        "extensions" => extensions
      }.compact
    end

    # Returns the plain-text content of the first Parts::Text, or nil.
    def text
      parts.find { |p| p.is_a?(Part::Text) }&.text
    end
  end
end
