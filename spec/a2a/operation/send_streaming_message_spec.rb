# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::SendStreamingMessage do
  let(:message) do
    A2A::Message.new(
      id: "msg-1",
      role: A2A::Role::USER,
      parts: [A2A::Part::Text.new(text: "hello")]
    )
  end

  def build(configuration: {})
    described_class.new(message, configuration: configuration)
  end

  def sse_event(result_hash)
    "data: #{JSON.generate({ "jsonrpc" => "2.0", "id" => "1", "result" => result_hash })}\n\n"
  end

  def protocol_binding_yielding(body)
    double("protocol_binding").tap do |t|
      allow(t).to receive(:stream) do |_method, _params, &block|
        block.call(StringIO.new(body))
      end
    end
  end

  def task_result(state: A2A::Task::State::WORKING)
    { "task" => { "id" => "task-1", "status" => { "state" => state }, "artifacts" => [], "history" => [] } }
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

  def artifact_update_result
    {
      "artifactUpdate" => {
        "taskId" => "task-1",
        "contextId" => "ctx-1",
        "artifact" => { "artifactId" => "art-1", "parts" => [{ "text" => "chunk" }] },
        "append" => false,
        "lastChunk" => true
      }
    }
  end

  describe "#execute with a block" do
    it "yields a Streaming::Response wrapping a Task" do
      events = []
      build.execute(protocol_binding_yielding(sse_event(task_result))) { |e| events << e }

      expect(events.length).to eq(1)
      expect(events.first).to be_a(A2A::Streaming::Response)
      expect(events.first).to be_task
      expect(events.first.payload).to be_a(A2A::Task)
    end

    it "yields a Streaming::Response wrapping a StatusUpdateEvent" do
      events = []
      build.execute(protocol_binding_yielding(sse_event(status_update_result))) { |e| events << e }

      expect(events.first).to be_status_update
      expect(events.first.payload).to be_a(A2A::Streaming::StatusUpdateEvent)
    end

    it "yields a Streaming::Response wrapping an ArtifactUpdateEvent" do
      events = []
      build.execute(protocol_binding_yielding(sse_event(artifact_update_result))) { |e| events << e }

      expect(events.first).to be_artifact_update
      expect(events.first.payload).to be_a(A2A::Streaming::ArtifactUpdateEvent)
    end

    it "yields multiple events" do
      events = []
      body = sse_event(task_result) + sse_event(status_update_result)
      build.execute(protocol_binding_yielding(body)) { |e| events << e }

      expect(events.length).to eq(2)
      expect(events.first).to be_task
      expect(events.last).to be_status_update
    end

    it "skips non-data SSE fields" do
      events = []
      body = "event: update\n" + sse_event(task_result)
      build.execute(protocol_binding_yielding(body)) { |e| events << e }

      expect(events.length).to eq(1)
    end

    it "stops after a final status update" do
      events = []
      body = sse_event(task_result) +
             sse_event(status_update_result(final: true)) +
             sse_event(task_result)
      build.execute(protocol_binding_yielding(body)) { |e| events << e }

      expect(events.length).to eq(2)
      expect(events.last).to be_status_update
    end

    it "raises an A2A error when the SSE envelope contains a JSON-RPC error" do
      body = "data: #{JSON.generate({ "jsonrpc" => "2.0", "id" => "1", "error" => { "code" => -32001, "message" => "task not found" } })}\n\n"

      expect { build.execute(protocol_binding_yielding(body)) { |_e| } }
        .to raise_error(A2A::TaskNotFoundError, "task not found")
    end

    it "passes the message params to the binding" do
      received = nil
      pb = double("protocol_binding")
      allow(pb).to receive(:stream) do |_method, params, &block|
        received = params
        block.call(StringIO.new(""))
      end

      build.execute(pb) { |_e| }

      expect(received["message"]).to eq(message.to_h)
    end
  end

  describe "#execute without a block" do
    it "returns a Subscription" do
      result = build.execute(protocol_binding_yielding(sse_event(task_result)))

      expect(result).to be_a(A2A::Streaming::Subscription)
    end

    it "the subscription is enumerable" do
      events = build.execute(protocol_binding_yielding(sse_event(task_result))).to_a

      expect(events.length).to eq(1)
      expect(events.first).to be_task
    end
  end

  describe "#params" do
    it "omits configuration when no options are set" do
      expect(build.params).not_to have_key("configuration")
    end

    it "includes acceptedOutputModes when provided" do
      params = build(configuration: { accepted_output_modes: ["text/plain"] }).params

      expect(params["configuration"]).to eq("acceptedOutputModes" => ["text/plain"])
    end

    it "includes historyLength when provided" do
      params = build(configuration: { history_length: 5 }).params

      expect(params["configuration"]).to eq("historyLength" => 5)
    end
  end
end
