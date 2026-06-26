# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module A2A
  module PushNotification
    class Dispatcher
      def initialize(transport: Transport.new)
        @transport = transport
      end

      def dispatch(config, event)
        headers = {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
        headers["Authorization"] = config.authentication.authorization_header if config.authentication

        @transport.post(config.url, body: event.to_h, headers: headers)
      end

      class Transport
        def post(url, body:, headers:)
          uri = URI.parse(url)
          handle(http_for(uri).request(build_request(uri, body, headers)))
        end

        private

        def handle(response)
          return if (200..299).cover?(response.code.to_i)

          raise TransportError, "push notification delivery failed: HTTP #{response.code}"
        end

        def http_for(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          http
        end

        def build_request(uri, body, headers)
          request = Net::HTTP::Post.new(uri.request_uri, headers)
          request.body = JSON.generate(body)
          request
        end
      end
    end
  end
end
