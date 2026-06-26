# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module A2A
  module Protocol
    class JsonRpc
      class Transport
        def post(url, body:, headers:)
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          request = Net::HTTP::Post.new(uri.request_uri, headers)
          request.body = JSON.generate(body)
          response = http.request(request)
          handle_response(response)
        end

        def stream(url, headers:, method: :post, body: {}, query: {}, &)
          uri = URI.parse(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          http.request(build_stream_request(uri, method, headers, body, query), &)
        end

        private

        def build_stream_request(uri, method, headers, body, query)
          case method
          when :post
            req = Net::HTTP::Post.new(uri.request_uri, headers)
            req.body = JSON.generate(body)
            req
          when :get
            uri.query = URI.encode_www_form(query) unless query.empty?
            Net::HTTP::Get.new(uri.request_uri, headers)
          end
        end

        def handle_response(response)
          case response.code.to_i
          when 200..299 then JSON.parse(response.body)
          when 401 then raise AuthenticationError, "HTTP 401"
          when 403 then raise AuthorizationError, "HTTP 403"
          when 404 then raise TaskNotFoundError, "HTTP 404"
          else raise TransportError, "HTTP #{response.code}"
          end
        end
      end
    end
  end
end
