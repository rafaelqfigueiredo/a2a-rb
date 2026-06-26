# frozen_string_literal: true

module A2A
  module SecurityScheme
    class HTTPAuth
      attr_reader :scheme, :bearer_format, :description

      def initialize(scheme:, bearer_format: nil, description: nil)
        @scheme = scheme
        @bearer_format = bearer_format
        @description = description
      end

      def self.from_h(hash)
        new(
          scheme: hash.fetch("scheme"),
          bearer_format: hash["bearerFormat"],
          description: hash["description"]
        )
      end

      def to_h
        {
          "httpAuthSecurityScheme" => {
            "scheme" => scheme,
            "bearerFormat" => bearer_format,
            "description" => description
          }.compact
        }
      end
    end
  end
end
