# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::JSONRPCEnvelope do
  describe ".success" do
    it "builds a 2.0 success envelope" do
      result = described_class.success(id: "1", result: { "foo" => "bar" })

      expect(result).to eq("jsonrpc" => "2.0", "id" => "1", "result" => { "foo" => "bar" })
    end

    it "accepts nil id" do
      result = described_class.success(id: nil, result: {})

      expect(result["id"]).to be_nil
    end
  end

  describe ".error" do
    it "uses the error code when available" do
      err = A2A::TaskNotFoundError.new("not found", code: -32001)
      result = described_class.error(id: "1", error: err)

      expect(result["error"]["code"]).to eq(-32001)
      expect(result["error"]["message"]).to eq("not found")
    end

    it "falls back to -32603 for plain StandardError" do
      err = StandardError.new("boom")
      result = described_class.error(id: "1", error: err)

      expect(result["error"]["code"]).to eq(-32603)
    end

    it "falls back to -32603 when A2A::Error has no code" do
      err = A2A::Error.new("oops")
      result = described_class.error(id: "1", error: err)

      expect(result["error"]["code"]).to eq(-32603)
    end
  end

  describe ".parse_request" do
    it "returns id, method, params" do
      hash = { "jsonrpc" => "2.0", "id" => "42", "method" => "SendMessage", "params" => { "x" => 1 } }
      id, method, params = described_class.parse_request(hash)

      expect(id).to eq("42")
      expect(method).to eq("SendMessage")
      expect(params).to eq("x" => 1)
    end

    it "defaults params to empty hash when absent" do
      hash = { "id" => "1", "method" => "GetTask" }
      _, _, params = described_class.parse_request(hash)

      expect(params).to eq({})
    end

    it "raises InvalidRequestError when method is missing" do
      expect { described_class.parse_request({ "id" => "1" }) }
        .to raise_error(A2A::InvalidRequestError, /missing method/)
    end
  end
end
