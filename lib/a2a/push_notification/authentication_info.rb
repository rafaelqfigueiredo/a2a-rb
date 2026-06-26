# frozen_string_literal: true

module A2A
  module PushNotification
    class AuthenticationInfo
      attr_reader :scheme, :credentials

      def initialize(scheme:, credentials: nil)
        @scheme = scheme
        @credentials = credentials
      end

      def self.from_h(hash)
        new(scheme: hash.fetch("scheme"), credentials: hash["credentials"])
      end

      def to_h
        {
          "scheme" => scheme,
          "credentials" => credentials
        }.compact
      end

      def authorization_header
        credentials ? "#{scheme} #{credentials}" : scheme
      end
    end
  end
end
