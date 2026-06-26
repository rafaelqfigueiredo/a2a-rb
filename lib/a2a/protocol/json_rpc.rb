# frozen_string_literal: true

require "securerandom"
require_relative "json_rpc/transport"

module A2A
  module Protocol
    class JsonRpc
      attr_reader :url, :version, :headers, :extensions

      def initialize(url:, version: Versioning::CURRENT, headers: {}, extensions: [], transport: Transport.new)
        @url = url
        @version = version
        @headers = headers
        @extensions = extensions
        @transport = transport
        @built_headers = build_headers
      end

      def post(method, params = {})
        @transport.post(@url, body: build_envelope(method, params), headers: @built_headers)
      end

      def stream(method, params = {}, &)
        sse_headers = @built_headers.merge("Accept" => "text/event-stream")
        @transport.stream(@url, headers: sse_headers, method: :post, body: build_envelope(method, params), &)
      end

      private

      def build_envelope(method, params)
        {
          "jsonrpc" => "2.0",
          "method" => method,
          "id" => SecureRandom.uuid,
          "params" => params
        }
      end

      def build_headers
        h = default_headers.merge(@headers)
        h["A2A-Extensions"] = @extensions.join(", ") unless @extensions.empty?
        h
      end

      def default_headers
        {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "A2A-Version" => @version
        }
      end
    end
  end
end
