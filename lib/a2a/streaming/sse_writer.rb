# frozen_string_literal: true

require "json"

module A2A
  module Streaming
    # Server-side counterpart to SseParser. Formats Streaming::Response objects
    # (or raw hashes) as SSE frames ready to write to an HTTP response body.
    module SSEWriter
      # Returns the SSE wire representation of a Streaming::Response as a String.
      # The result includes the trailing blank line that delimits SSE events.
      def self.encode(response, id: nil)
        payload = response.is_a?(Response) ? response.to_h : response
        envelope = JSONRPCEnvelope.success(id: id, result: payload)
        "data: #{JSON.generate(envelope)}\n\n"
      end

      # Encodes a JSON-RPC error as an SSE frame.
      def self.encode_error(error, id: nil)
        envelope = JSONRPCEnvelope.error(id: id, error: error)
        "data: #{JSON.generate(envelope)}\n\n"
      end
    end
  end
end
