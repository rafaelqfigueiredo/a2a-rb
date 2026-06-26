# frozen_string_literal: true

require_relative "http_json/transport"

module A2A
  module Protocol
    class HttpJson
      attr_reader :url, :version, :headers, :extensions

      def initialize(url:, version: Versioning::CURRENT, headers: {}, extensions: [], transport: Transport.new)
        @url = url.chomp("/")
        @version = version
        @headers = headers
        @extensions = extensions
        @transport = transport
        @built_headers = build_headers
      end

      def get(path, query: {})
        @transport.get("#{@url}#{path}", query: query, headers: @built_headers)
      end

      def post(path, body: {})
        @transport.post("#{@url}#{path}", body: body, headers: @built_headers)
      end

      def delete(path)
        @transport.delete("#{@url}#{path}", headers: @built_headers)
      end

      def stream(path, method: :post, body: {}, query: {}, &)
        sse_headers = @built_headers.merge("Accept" => "text/event-stream")
        @transport.stream("#{@url}#{path}", headers: sse_headers, method: method, body: body, query: query, &)
      end

      private

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
