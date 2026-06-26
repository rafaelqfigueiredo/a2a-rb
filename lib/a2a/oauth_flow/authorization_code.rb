# frozen_string_literal: true

module A2A
  module OAuthFlow
    class AuthorizationCode
      attr_reader :authorization_url, :token_url, :refresh_url, :scopes, :pkce_required

      def initialize(authorization_url:, token_url:, scopes:, refresh_url: nil, pkce_required: nil)
        @authorization_url = authorization_url
        @token_url = token_url
        @scopes = scopes
        @refresh_url = refresh_url
        @pkce_required = pkce_required
      end

      def self.from_h(hash)
        new(
          authorization_url: hash.fetch("authorizationUrl"),
          scopes: hash.fetch("scopes"),
          token_url: hash.fetch("tokenUrl"),
          refresh_url: hash["refreshUrl"],
          pkce_required: hash["pkceRequired"]
        )
      end

      def to_h
        {
          "authorizationUrl" => authorization_url,
          "tokenUrl" => token_url,
          "scopes" => scopes,
          "refreshUrl" => refresh_url,
          "pkceRequired" => pkce_required
        }.compact
      end
    end
  end
end
