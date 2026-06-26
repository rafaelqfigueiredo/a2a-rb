# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::GetTask do
  def task_hash(id: "task-1", state: A2A::Task::State::COMPLETED)
    { "id" => id, "status" => { "state" => state }, "artifacts" => [], "history" => [] }
  end

  def protocol_binding_returning(result)
    double("protocol_binding").tap { |t| allow(t).to receive(:post).and_return({ "result" => result }) }
  end

  describe "#execute" do
    it "returns a Task" do
      op = described_class.new(id: "task-1")
      result = op.execute(protocol_binding_returning(task_hash))

      expect(result).to be_a(A2A::Task)
      expect(result.id).to eq("task-1")
    end

    it "raises an A2A error on JSON-RPC error" do
      pb = double("protocol_binding")
      allow(pb).to receive(:post).and_return(
        { "error" => { "code" => -32001, "message" => "not found" } }
      )

      expect { described_class.new(id: "task-1").execute(pb) }
        .to raise_error(A2A::TaskNotFoundError, "not found")
    end
  end

  describe "#params" do
    it "sets id" do
      expect(described_class.new(id: "task-1").params).to eq("id" => "task-1")
    end

    it "includes historyLength when provided" do
      params = described_class.new(id: "task-1", history_length: 5).params

      expect(params["historyLength"]).to eq(5)
    end

    it "includes tenant when provided" do
      params = described_class.new(id: "task-1", tenant: "acme").params

      expect(params["tenant"]).to eq("acme")
    end

    it "omits nil optional fields" do
      expect(described_class.new(id: "task-1").params.keys).to eq(["id"])
    end
  end
end
