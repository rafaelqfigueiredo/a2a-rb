# frozen_string_literal: true

module A2A
  module SecurityScheme
    class APIKey
      attr_reader :name, :location, :description

      def initialize(name:, location:, description: nil)
        @name = name
        @location = location
        @description = description
      end

      def self.from_h(hash)
        new(
          name: hash.fetch("name"),
          location: hash.fetch("location"),
          description: hash["description"]
        )
      end

      def to_h
        {
          "apiKeySecurityScheme" => {
            "name" => name,
            "location" => location,
            "description" => description
          }.compact
        }
      end
    end
  end
end
