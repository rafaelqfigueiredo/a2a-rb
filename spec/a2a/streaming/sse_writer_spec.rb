# frozen_string_literal: true

require "a2a"
require "json"

RSpec.describe A2A::Streaming::SSEWriter do
  let(:task_h) do
    { "id" => "t1", "status" => { "state" => A2A::Task::State::WORKING } }
  end

  let(:task) { A2A::Task.from_h(task_h) }
  let(:response) { A2A::Streaming::Response.new(:task, task) }

  describe ".encode" do
    it "returns an SSE frame string ending with a blank line" do
      frame = described_class.encode(response, id: "rpc-1")

      expect(frame).to start_with("data: ")
      expect(frame).to end_with("\n\n")
    end

    it "wraps the payload in a JSON-RPC success envelope" do
      frame = described_class.encode(response, id: "rpc-1")
      envelope = JSON.parse(frame.delete_prefix("data: ").strip)

      expect(envelope["jsonrpc"]).to eq("2.0")
      expect(envelope["id"]).to eq("rpc-1")
      expect(envelope["result"]).to have_key("task")
    end

    it "accepts a raw hash instead of a Response object" do
      frame = described_class.encode({ "task" => task_h }, id: "1")
      envelope = JSON.parse(frame.delete_prefix("data: ").strip)

      expect(envelope["result"]).to have_key("task")
    end
  end

  describe ".encode_error" do
    it "returns an SSE frame with a JSON-RPC error envelope" do
      err = A2A::TaskNotFoundError.new("gone", code: -32001)
      frame = described_class.encode_error(err, id: "rpc-2")
      envelope = JSON.parse(frame.delete_prefix("data: ").strip)

      expect(envelope["error"]["code"]).to eq(-32001)
      expect(envelope["error"]["message"]).to eq("gone")
    end
  end

  describe "round-trip with SseParser" do
    it "encodes then re-parses to the original Response" do
      frame = described_class.encode(response, id: "1")
      parsed = []
      A2A::Streaming::SseParser.each(StringIO.new(frame)) { |e| parsed << e }

      expect(parsed.length).to eq(1)
      expect(parsed.first).to be_task
      expect(parsed.first.payload.id).to eq("t1")
    end
  end
end
