# frozen_string_literal: true

require_relative "a2a/version"
require_relative "a2a/task"
require_relative "a2a/role"
require_relative "a2a/part"
require_relative "a2a/oauth_flow"
require_relative "a2a/security_scheme"
require_relative "a2a/security_requirement"
require_relative "a2a/push_notification"
require_relative "a2a/message"
require_relative "a2a/artifact"
require_relative "a2a/streaming"
require_relative "a2a/agent_extension"
require_relative "a2a/agent_interface"
require_relative "a2a/agent_capabilities"
require_relative "a2a/agent_provider"
require_relative "a2a/agent_skill"
require_relative "a2a/agent_card"
require_relative "a2a/versioning"
require_relative "a2a/protocol/json_rpc"
require_relative "a2a/protocol/http_json"
require_relative "a2a/operation"
require_relative "a2a/client"
require_relative "a2a/discovery"
require_relative "a2a/json_rpc_envelope"
require_relative "a2a/streaming/sse_writer"
require_relative "a2a/operation/send_message_request"

module A2A
  class Error < StandardError
    attr_reader :code, :details

    def initialize(message, code: nil, details: nil)
      super(message)

      @code    = code
      @details = details
    end
  end

  # Transport / HTTP errors
  class TransportError < Error; end
  class AuthenticationError < Error; end
  class AuthorizationError < Error; end
  class ValidationError < Error; end

  # Standard JSON-RPC errors
  class JSONParseError < Error; end
  class InvalidRequestError < Error; end
  class MethodNotFoundError < Error; end
  class InvalidParamsError < Error; end
  class InternalError < Error; end

  # A2A protocol errors
  class TaskNotFoundError < Error; end
  class TaskNotCancelableError < Error; end
  class PushNotificationNotSupportedError < Error; end
  class UnsupportedOperationError < Error; end
  class ContentTypeNotSupportedError < Error; end
  class InvalidAgentResponseError < Error; end
  class ExtendedAgentCardNotConfiguredError < Error; end
  class ExtensionSupportRequiredError < Error; end
  class VersionNotSupportedError < Error; end

  CODE_MAP = {
    -32700 => JSONParseError,
    -32600 => InvalidRequestError,
    -32601 => MethodNotFoundError,
    -32602 => InvalidParamsError,
    -32603 => InternalError,
    -32001 => TaskNotFoundError,
    -32002 => TaskNotCancelableError,
    -32003 => PushNotificationNotSupportedError,
    -32004 => UnsupportedOperationError,
    -32005 => ContentTypeNotSupportedError,
    -32006 => InvalidAgentResponseError,
    -32007 => ExtendedAgentCardNotConfiguredError,
    -32008 => ExtensionSupportRequiredError,
    -32009 => VersionNotSupportedError
  }.freeze

  def self.from_json_rpc_error(hash)
    (CODE_MAP[hash["code"]] || Error).new(
      hash["message"] || "unknown A2A error",
      code: hash["code"],
      details: hash["data"]
    )
  end
end
