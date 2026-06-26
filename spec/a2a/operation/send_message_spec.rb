# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::SendMessage do
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

  def protocol_binding_returning(result_hash)
    double("protocol_binding").tap do |t|
      allow(t).to receive(:post).and_return({ "result" => result_hash })
    end
  end

  def task_hash(state: A2A::Task::State::COMPLETED)
    { "id" => "task-1", "status" => { "state" => state }, "artifacts" => [], "history" => [] }
  end

  def message_hash
    { "messageId" => "msg-2", "role" => A2A::Role::AGENT, "parts" => [{ "text" => "hi" }] }
  end

  describe "#execute" do
    context "when the result contains a 'task' key" do
      it "returns a Task" do
        result = build.execute(protocol_binding_returning("task" => task_hash))

        expect(result).to be_a(A2A::Task)
        expect(result.id).to eq("task-1")
      end
    end

    context "when the result contains a 'message' key" do
      it "returns a Message" do
        result = build.execute(protocol_binding_returning("message" => message_hash))

        expect(result).to be_a(A2A::Message)
        expect(result.id).to eq("msg-2")
      end
    end

    context "when the result is unrecognisable" do
      it "raises InvalidAgentResponseError" do
        expect { build.execute(protocol_binding_returning("unknown" => "payload")) }
          .to raise_error(A2A::InvalidAgentResponseError)
      end
    end

    it "raises an A2A error when the binding returns a JSON-RPC error" do
      pb = double("protocol_binding")
      allow(pb).to receive(:post).and_return(
        { "error" => { "code" => -32001, "message" => "task not found" } }
      )

      expect { build.execute(pb) }.to raise_error(A2A::TaskNotFoundError, "task not found")
    end

    it "passes the message params to the binding" do
      received = nil
      pb = double("protocol_binding")
      allow(pb).to receive(:post) do |_method, p|
        received = p
        { "result" => { "task" => task_hash } }
      end

      build.execute(pb)

      expect(received["message"]).to eq(message.to_h)
    end
  end

  describe "#params" do
    it "omits the configuration key when configuration is empty" do
      expect(build.params).not_to have_key("configuration")
    end

    it "includes configuration when options are set" do
      params = build(configuration: { accepted_output_modes: ["text/plain"] }).params

      expect(params["configuration"]).to eq("acceptedOutputModes" => ["text/plain"])
    end

    it "includes metadata when provided" do
      op = described_class.new(message, metadata: { "key" => "value" })

      expect(op.params["metadata"]).to eq("key" => "value")
    end

    it "includes tenant when provided" do
      op = described_class.new(message, tenant: "acme")

      expect(op.params["tenant"]).to eq("acme")
    end

    it "omits metadata when nil" do
      expect(build.params).not_to have_key("metadata")
    end

    it "omits tenant when nil" do
      expect(build.params).not_to have_key("tenant")
    end
  end
end
