# frozen_string_literal: true

module A2A
  class AgentInterface
    attr_reader :url, :protocol_binding, :protocol_version, :tenant

    JSONRPC = "JSONRPC"
    GRPC = "GRPC"
    HTTP_JSON = "HTTP+JSON"

    VALID_BINDINGS = [JSONRPC, GRPC, HTTP_JSON].freeze

    def initialize(url:, protocol_binding:, protocol_version:, tenant: nil)
      unless VALID_BINDINGS.include?(protocol_binding)
        raise ArgumentError, "protocol_binding must be one of #{VALID_BINDINGS.join(', ')}"
      end

      @url = url
      @protocol_binding = protocol_binding
      @protocol_version = protocol_version
      @tenant = tenant
    end

    def self.from_h(hash)
      new(
        url: hash.fetch("url"),
        protocol_binding: hash.fetch("protocolBinding"),
        protocol_version: hash.fetch("protocolVersion"),
        tenant: hash["tenant"]
      )
    end

    def to_h
      {
        "url" => url,
        "protocolBinding" => protocol_binding,
        "protocolVersion" => protocol_version,
        "tenant" => tenant
      }.compact
    end

    def json_rpc?
      protocol_binding == JSONRPC
    end

    def grpc?
      protocol_binding == GRPC
    end

    def http_json?
      protocol_binding == HTTP_JSON
    end
  end
end
