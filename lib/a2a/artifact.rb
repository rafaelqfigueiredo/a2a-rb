# frozen_string_literal: true

module A2A
  class Artifact
    attr_reader :id, :name, :description, :parts, :extensions, :metadata

    def initialize(id:, parts:, **kwargs)
      raise ArgumentError, "parts must contain at least one element" if Array(parts).empty?

      @id = id
      @parts = parts
      @name = kwargs[:name]
      @description = kwargs[:description]
      @extensions = kwargs[:extensions]
      @metadata = kwargs[:metadata]
    end

    def self.from_h(hash)
      new(
        id: hash.fetch("artifactId"),
        name: hash["name"],
        description: hash["description"],
        parts: Array(hash["parts"]).map { Part.from_h(_1) },
        extensions: hash["extensions"],
        metadata: hash["metadata"]
      )
    end

    def to_h
      {
        "parts" => parts.map(&:to_h),
        "artifactId" => id,
        "name" => name,
        "description" => description,
        "extensions" => extensions,
        "metadata" => metadata
      }.compact
    end
  end
end
