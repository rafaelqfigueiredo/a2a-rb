# frozen_string_literal: true

require_relative "security_scheme/api_key"
require_relative "security_scheme/http_auth"
require_relative "security_scheme/oauth2"
require_relative "security_scheme/open_id_connect"
require_relative "security_scheme/mutual_tls"

module A2A
  module SecurityScheme
    BUILDERS = {
      "apiKeySecurityScheme" => ->(v) { APIKey.from_h(v) },
      "httpAuthSecurityScheme" => ->(v) { HTTPAuth.from_h(v) },
      "oauth2SecurityScheme" => ->(v) { OAuth2.from_h(v) },
      "openIdConnectSecurityScheme" => ->(v) { OpenIDConnect.from_h(v) },
      "mtlsSecurityScheme" => ->(v) { MutualTLS.from_h(v) }
    }.freeze

    def self.from_h(hash)
      key, builder = BUILDERS.find { |k, _| hash.key?(k) }
      raise ArgumentError, "unknown SecurityScheme: #{hash.keys.inspect}" unless key

      builder.call(hash[key])
    end
  end
end
