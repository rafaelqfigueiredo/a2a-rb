# frozen_string_literal: true

module A2A
  module Operation
    class SubscribeToTask
      include Executable

      METHOD = "SubscribeToTask"

      attr_reader :id, :tenant

      def initialize(id:, tenant: nil)
        @id = id
        @tenant = tenant
      end

      def execute_json_rpc(protocol, &block)
        protocol.stream(METHOD, params) do |response|
          sub = Streaming::Subscription.new(response)
          return sub unless block

          sub.each(&block)
        end
      end

      def execute_http_json(protocol, &block)
        protocol.stream("/tasks/#{id}:subscribe", method: :get) do |response|
          sub = Streaming::Subscription.new(response)
          return sub unless block

          sub.each(&block)
        end
      end

      def params
        { "id" => id, "tenant" => tenant }.compact
      end
    end
  end
end
