# frozen_string_literal: true

module A2A
  module SecurityScheme
    class OAuth2
      attr_reader :flows, :oauth2_metadata_url, :description

      FLOW_TYPES = [
        OAuthFlow::AuthorizationCode,
        OAuthFlow::ClientCredentials,
        OAuthFlow::DeviceCode
      ].freeze

      def initialize(flows:, oauth2_metadata_url: nil, description: nil)
        unless flows.is_a?(Hash) && flows.size == 1 && FLOW_TYPES.any? { |t| flows.values.first.is_a?(t) }
          raise ArgumentError, "flows must be a Hash with exactly one OAuthFlow entry"
        end

        @flows = flows
        @oauth2_metadata_url = oauth2_metadata_url
        @description = description
      end

      def self.from_h(hash)
        new(
          flows: OAuthFlow.from_h(hash.fetch("flows")),
          oauth2_metadata_url: hash["oauth2MetadataUrl"],
          description: hash["description"]
        )
      end

      def to_h
        {
          "oauth2SecurityScheme" => {
            "flows" => serialize_flows,
            "oauth2MetadataUrl" => oauth2_metadata_url,
            "description" => description
          }.compact
        }
      end

      private

      def serialize_flows
        flows.each_with_object({}) do |(key, flow), hash|
          protocol_key = key.to_s.gsub(/_([a-z])/) { ::Regexp.last_match(1).upcase }
          hash[protocol_key] = flow.to_h
        end
      end
    end
  end
end
