# frozen_string_literal: true

module A2A
  class AgentSkill
    attr_reader :id, :name, :description, :tags, :examples, :input_modes, :output_modes, :security_requirements

    def initialize(id:, name:, description:, tags:, **kwargs)
      raise ArgumentError, "tags must contain at least one element" if Array(tags).empty?

      @id = id
      @name = name
      @description = description
      @tags = tags
      @examples = kwargs[:examples]
      @input_modes = kwargs[:input_modes]
      @output_modes = kwargs[:output_modes]
      @security_requirements = kwargs[:security_requirements]
    end

    def self.from_h(hash)
      new(
        id: hash.fetch("id"),
        name: hash.fetch("name"),
        description: hash.fetch("description"),
        tags: hash.fetch("tags"),
        examples: hash["examples"],
        input_modes: hash["inputModes"],
        output_modes: hash["outputModes"],
        security_requirements: hash["securityRequirements"]&.map { SecurityRequirement.from_h(it) }
      )
    end

    def to_h
      {
        "id" => id,
        "name" => name,
        "description" => description,
        "tags" => tags,
        "examples" => examples,
        "inputModes" => input_modes,
        "outputModes" => output_modes,
        "securityRequirements" => security_requirements&.map(&:to_h)
      }.compact
    end
  end
end
