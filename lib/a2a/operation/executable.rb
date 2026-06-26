# frozen_string_literal: true

module A2A
  module Operation
    module Executable
      def execute(protocol, &)
        if protocol.is_a?(Protocol::HttpJson)
          execute_http_json(protocol, &)
        else
          execute_json_rpc(protocol, &)
        end
      end

      def execute_json_rpc(*)
        raise NotImplementedError, "#{self.class}#execute_json_rpc is not implemented"
      end

      def execute_http_json(*)
        raise NotImplementedError, "#{self.class}#execute_http_json is not implemented"
      end

      def params
        raise NotImplementedError, "#{self.class}#params is not implemented"
      end
    end
  end
end
