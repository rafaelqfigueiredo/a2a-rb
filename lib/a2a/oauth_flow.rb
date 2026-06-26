# frozen_string_literal: true

require_relative "oauth_flow/authorization_code"
require_relative "oauth_flow/client_credentials"
require_relative "oauth_flow/device_code"

module A2A
  module OAuthFlow
    FLOW_KEYS = %w[authorizationCode clientCredentials deviceCode].freeze
    DEPRECATED_FLOW_KEYS = %w[implicit password].freeze

    def self.from_h(hash)
      reject_deprecated!(hash)
      matched = FLOW_KEYS.count { |k| hash.key?(k) }
      raise ArgumentError, "OAuthFlows must contain exactly one flow type, got #{matched}" unless matched == 1

      build_flows(hash)
    end

    def self.build_flows(hash)
      {}.tap do |flows|
        flows[:authorization_code] = AuthorizationCode.from_h(hash["authorizationCode"]) if hash["authorizationCode"]
        flows[:client_credentials] = ClientCredentials.from_h(hash["clientCredentials"]) if hash["clientCredentials"]
        flows[:device_code] = DeviceCode.from_h(hash["deviceCode"]) if hash["deviceCode"]
      end
    end

    def self.reject_deprecated!(hash)
      deprecated = DEPRECATED_FLOW_KEYS.select { |k| hash.key?(k) }
      return unless deprecated.any?

      raise ArgumentError,
            "OAuthFlows contains deprecated flow(s): #{deprecated.join(', ')} — use authorizationCode or deviceCode"
    end
    private_class_method :build_flows, :reject_deprecated!
  end
end
