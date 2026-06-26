# frozen_string_literal: true

module A2A
  module OAuthFlow
    class DeviceCode
      attr_reader :device_authorization_url, :token_url, :refresh_url, :scopes

      def initialize(device_authorization_url:, token_url:, scopes:, refresh_url: nil)
        @device_authorization_url = device_authorization_url
        @token_url = token_url
        @scopes = scopes
        @refresh_url = refresh_url
      end

      def self.from_h(hash)
        new(
          device_authorization_url: hash.fetch("deviceAuthorizationUrl"),
          scopes: hash.fetch("scopes"),
          token_url: hash.fetch("tokenUrl"),
          refresh_url: hash["refreshUrl"]
        )
      end

      def to_h
        {
          "deviceAuthorizationUrl" => device_authorization_url,
          "tokenUrl" => token_url,
          "scopes" => scopes,
          "refreshUrl" => refresh_url
        }.compact
      end
    end
  end
end
