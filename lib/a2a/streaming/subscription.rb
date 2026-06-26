# frozen_string_literal: true

module A2A
  module Streaming
    class Subscription
      include Enumerable

      def initialize(io)
        @io = io
      end

      def each(&block)
        return enum_for(:each) unless block

        SseParser.each(reader) do |event|
          yield event
          break if terminal?(event)
        end
      end

      private

      # Net::HTTPResponse streams via read_body; plain IO responds to each_line.
      def reader
        return @io unless @io.respond_to?(:read_body)

        ChunkedReader.new(@io)
      end

      def terminal?(event)
        case event.type
        when :status_update
          payload = event.payload
          payload.final? || Task::State.terminal?(payload.status.state)
        when :task
          Task::State.terminal?(event.payload.status.state)
        else
          false
        end
      end

      # Wraps Net::HTTPResponse so SseParser can call each_line on it.
      class ChunkedReader
        def initialize(response)
          @response = response
        end

        def each_line(&block)
          @response.read_body do |chunk|
            chunk.each_line(&block)
          end
        end
      end
    end
  end
end
