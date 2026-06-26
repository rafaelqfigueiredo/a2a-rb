# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::SubscribeToTask do
  def sse_event(result_hash)
    "data: #{JSON.generate({ "jsonrpc" => "2.0", "id" => "1", "result" => result_hash })}\n\n"
  end

  def status_update_result(state: A2A::Task::State::COMPLETED, final: false)
    {
      "statusUpdate" => {
        "taskId" => "task-1",
        "contextId" => "ctx-1",
        "status" => { "state" => state },
        "final" => final
      }
    }
  end

  def task_result
    { "task" => { "id" => "task-1", "status" => { "state" => A2A::Task::State::WORKING }, "artifacts" => [], "history" => [] } }
  end

  def protocol_binding_yielding(body)
    double("protocol_binding").tap do |t|
      allow(t).to receive(:stream) do |_params, &block|
        block.call(StringIO.new(body))
      end
    end
  end

  describe "#execute with a block" do
    it "yields Streaming::Response events" do
      events = []
      described_class.new(id: "task-1").execute(protocol_binding_yielding(sse_event(task_result))) { |e| events << e }

      expect(events.length).to eq(1)
      expect(events.first).to be_task
    end

    it "yields status updates" do
      events = []
      described_class.new(id: "task-1").execute(protocol_binding_yielding(sse_event(status_update_result))) { |e| events << e }

      expect(events.first).to be_status_update
    end

    it "stops after a final status update" do
      events = []
      body = sse_event(task_result) +
             sse_event(status_update_result(final: true)) +
             sse_event(task_result)
      described_class.new(id: "task-1").execute(protocol_binding_yielding(body)) { |e| events << e }

      expect(events.length).to eq(2)
      expect(events.last).to be_status_update
    end

    it "raises on JSON-RPC error in stream" do
      body = "data: #{JSON.generate({ "error" => { "code" => -32001, "message" => "not found" } })}\n\n"

      expect { described_class.new(id: "task-1").execute(protocol_binding_yielding(body)) { |_e| } }
        .to raise_error(A2A::TaskNotFoundError)
    end
  end

  describe "#execute without a block" do
    it "returns a Subscription" do
      result = described_class.new(id: "task-1").execute(protocol_binding_yielding(sse_event(task_result)))

      expect(result).to be_a(A2A::Streaming::Subscription)
    end
  end

  describe "#params" do
    it "sets id" do
      expect(described_class.new(id: "task-1").params).to eq("id" => "task-1")
    end

    it "includes tenant when provided" do
      expect(described_class.new(id: "task-1", tenant: "acme").params["tenant"]).to eq("acme")
    end
  end
end
