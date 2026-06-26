# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::DeleteTaskPushNotificationConfig do
  def protocol_binding_returning(result)
    double("protocol_binding").tap { |t| allow(t).to receive(:post).and_return({ "result" => result }) }
  end

  describe "#execute" do
    it "returns nil on success" do
      result = described_class.new(task_id: "task-1", id: "cfg-1").execute(protocol_binding_returning(nil))

      expect(result).to be_nil
    end

    it "raises on JSON-RPC error" do
      pb = double("protocol_binding")
      allow(pb).to receive(:post).and_return(
        { "error" => { "code" => -32003, "message" => "push not supported" } }
      )

      expect { described_class.new(task_id: "task-1", id: "cfg-1").execute(pb) }
        .to raise_error(A2A::PushNotificationNotSupportedError)
    end
  end

  describe "#params" do
    it "sets taskId and id" do
      params = described_class.new(task_id: "task-1", id: "cfg-1").params

      expect(params).to eq("taskId" => "task-1", "id" => "cfg-1")
    end

    it "includes tenant when provided" do
      params = described_class.new(task_id: "task-1", id: "cfg-1", tenant: "acme").params

      expect(params["tenant"]).to eq("acme")
    end
  end
end
