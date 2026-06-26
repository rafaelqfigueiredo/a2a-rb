# frozen_string_literal: true

module A2A
  module OAuthFlow
    class ClientCredentials
      attr_reader :token_url, :refresh_url, :scopes

      def initialize(token_url:, scopes:, refresh_url: nil)
        @token_url = token_url
        @scopes = scopes
        @refresh_url = refresh_url
      end

      def self.from_h(hash)
        new(
          scopes: hash.fetch("scopes"),
          token_url: hash.fetch("tokenUrl"),
          refresh_url: hash["refreshUrl"]
        )
      end

      def to_h
        {
          "tokenUrl" => token_url,
          "scopes" => scopes,
          "refreshUrl" => refresh_url
        }.compact
      end
    end
  end
end
