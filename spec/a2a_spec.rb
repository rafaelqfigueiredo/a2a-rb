# frozen_string_literal: true

require "a2a"

RSpec.describe A2A do
  it "has a version number" do
    expect(A2A::VERSION).not_to be_nil
  end

  describe "error hierarchy" do
    it "A2A::Error exposes code and details" do
      err = A2A::Error.new("something went wrong", code: "SomeCode", details: { "key" => "val" })

      expect(err.message).to eq "something went wrong"
      expect(err.code).to eq "SomeCode"
      expect(err.details).to eq({ "key" => "val" })
    end

    it "transport errors inherit from A2A::Error" do
      expect(A2A::TransportError.ancestors).to include(A2A::Error)
      expect(A2A::AuthenticationError.ancestors).to include(A2A::Error)
      expect(A2A::AuthorizationError.ancestors).to include(A2A::Error)
      expect(A2A::ValidationError.ancestors).to include(A2A::Error)
    end

    it "standard JSON-RPC errors inherit from A2A::Error" do
      json_rpc_errors = [
        A2A::JSONParseError,
        A2A::InvalidRequestError,
        A2A::MethodNotFoundError,
        A2A::InvalidParamsError,
        A2A::InternalError
      ]

      json_rpc_errors.each do |klass|
        expect(klass.ancestors).to include(A2A::Error), "expected #{klass} to inherit from A2A::Error"
      end
    end

    it "protocol errors inherit from A2A::Error" do
      protocol_errors = [
        A2A::TaskNotFoundError,
        A2A::TaskNotCancelableError,
        A2A::PushNotificationNotSupportedError,
        A2A::UnsupportedOperationError,
        A2A::ContentTypeNotSupportedError,
        A2A::InvalidAgentResponseError,
        A2A::ExtendedAgentCardNotConfiguredError,
        A2A::ExtensionSupportRequiredError,
        A2A::VersionNotSupportedError
      ]

      protocol_errors.each do |klass|
        expect(klass.ancestors).to include(A2A::Error), "expected #{klass} to inherit from A2A::Error"
      end
    end
  end

  describe ".from_json_rpc_error" do
    it "returns the specific error class for a known code" do
      err = described_class.from_json_rpc_error("code" => -32001, "message" => "task missing")

      expect(err).to be_a(A2A::TaskNotFoundError)
      expect(err.message).to eq "task missing"
      expect(err.code).to eq(-32001)
    end

    it "falls back to A2A::Error for an unknown code" do
      err = described_class.from_json_rpc_error("code" => -99999, "message" => "something")

      expect(err).to be_a(A2A::Error)
      expect(err.class).to eq A2A::Error
    end

    it "defaults message to 'unknown A2A error' when absent" do
      err = described_class.from_json_rpc_error("code" => -32001)

      expect(err.message).to eq "unknown A2A error"
    end

    it "sets details from the data field" do
      err = described_class.from_json_rpc_error("code" => -32001, "data" => { "id" => "t1" })

      expect(err.details).to eq({ "id" => "t1" })
    end

    it "maps every known code to its error class" do
      {
        -32700 => A2A::JSONParseError,
        -32600 => A2A::InvalidRequestError,
        -32601 => A2A::MethodNotFoundError,
        -32602 => A2A::InvalidParamsError,
        -32603 => A2A::InternalError,
        -32001 => A2A::TaskNotFoundError,
        -32002 => A2A::TaskNotCancelableError,
        -32003 => A2A::PushNotificationNotSupportedError,
        -32004 => A2A::UnsupportedOperationError,
        -32005 => A2A::ContentTypeNotSupportedError,
        -32006 => A2A::InvalidAgentResponseError,
        -32007 => A2A::ExtendedAgentCardNotConfiguredError,
        -32008 => A2A::ExtensionSupportRequiredError,
        -32009 => A2A::VersionNotSupportedError
      }.each do |code, klass|
        err = described_class.from_json_rpc_error("code" => code)
        expect(err).to be_a(klass), "expected code #{code} to map to #{klass}"
      end
    end
  end
end
