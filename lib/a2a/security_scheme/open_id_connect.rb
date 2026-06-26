# frozen_string_literal: true

module A2A
  module SecurityScheme
    class OpenIDConnect
      attr_reader :open_id_connect_url, :description

      def initialize(open_id_connect_url:, description: nil)
        @open_id_connect_url = open_id_connect_url
        @description = description
      end

      def self.from_h(hash)
        new(
          open_id_connect_url: hash.fetch("openIdConnectUrl"),
          description: hash["description"]
        )
      end

      def to_h
        {
          "openIdConnectSecurityScheme" => {
            "openIdConnectUrl" => open_id_connect_url,
            "description" => description
          }.compact
        }
      end
    end
  end
end
