# frozen_string_literal: true

module A2A
  module JSONRPCEnvelope
    # Builds a success response envelope.
    def self.success(id:, result:)
      { "jsonrpc" => "2.0", "id" => id, "result" => result }
    end

    # Builds an error response envelope from an A2A::Error or any StandardError.
    # If the error carries a numeric code it is used directly; otherwise falls
    # back to -32603 (InternalError).
    def self.error(id:, error:)
      code = error.respond_to?(:code) && error.code ? error.code : -32603
      {
        "jsonrpc" => "2.0",
        "id" => id,
        "error" => { "code" => code, "message" => error.message }
      }
    end

    # Parses the JSON-RPC id and method from a raw request hash.
    def self.parse_request(hash)
      id = hash["id"]
      method = hash["method"]
      params = hash["params"] || {}
      raise InvalidRequestError, "missing method" unless method

      [id, method, params]
    end
  end
end
