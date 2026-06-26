# frozen_string_literal: true

require "rack"
require "json"

module A2A
  module PushNotification
    class Receiver
      def initialize(app, path: "/a2a/webhook", scheme: "Bearer", credentials: nil, &handler)
        @app = app
        @path = path
        @scheme = scheme
        @credentials = credentials
        @handler = handler
      end

      def call(env)
        request = Rack::Request.new(env)
        return @app.call(env) unless request.post? && request.path == @path
        return unauthorized unless authorized?(request)

        handle_event(request)
      end

      private

      def handle_event(request)
        event = Streaming::Response.from_h(JSON.parse(request.body.read))
        @handler.call(event)
        json(200, { "ok" => true })
      rescue JSON::ParserError => e
        json(400, { "error" => "invalid JSON: #{e.message}" })
      rescue ArgumentError => e
        json(400, { "error" => e.message })
      end

      def authorized?(request)
        return true unless @credentials

        expected = "#{@scheme} #{@credentials}"
        actual = request.get_header("HTTP_AUTHORIZATION").to_s
        actual.casecmp(expected).zero?
      end

      def unauthorized
        json(401, { "error" => "unauthorized" })
      end

      def json(status, body)
        [status, { "Content-Type" => "application/json" }, [JSON.generate(body)]]
      end
    end
  end
end
