# frozen_string_literal: true

require "json"

module A2A
  module Streaming
    module SseParser
      # Parses a stream of SSE lines, yielding one Streaming::Response per
      # logical event (blank-line delimited, multi-line data: concatenated).
      def self.each(io, &block)
        buffer = +""

        io.each_line do |line|
          line = line.chomp

          if line.empty?
            emit(buffer, &block) unless buffer.empty?
            buffer = +""
          elsif line.start_with?("data:")
            # SSE spec: multiple data: lines are concatenated with U+000A
            buffer << "\n" unless buffer.empty?
            buffer << line.delete_prefix("data:").lstrip
          end
          # skip comment lines (":"), "event:", "id:", "retry:" fields
        end

        emit(buffer, &block) unless buffer.empty?
      end

      def self.emit(buffer)
        data = buffer.strip
        return if data == "[DONE]"

        envelope = JSON.parse(data)
        raise A2A.from_json_rpc_error(envelope["error"]) if envelope["error"]

        event = Response.from_h(Hash(envelope["result"]))
        yield event
      end
      private_class_method :emit
    end
  end
end
