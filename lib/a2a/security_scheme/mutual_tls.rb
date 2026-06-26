# frozen_string_literal: true

module A2A
  module SecurityScheme
    class MutualTLS
      attr_reader :description

      def initialize(description: nil)
        @description = description
      end

      def self.from_h(hash)
        new(description: hash["description"])
      end

      def to_h
        {
          "mtlsSecurityScheme" => {
            "description" => description
          }.compact
        }
      end
    end
  end
end
