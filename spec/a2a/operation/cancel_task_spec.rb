# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::CancelTask do
  def task_hash(state: A2A::Task::State::CANCELED)
    { "id" => "task-1", "status" => { "state" => state }, "artifacts" => [], "history" => [] }
  end

  def protocol_binding_returning(result)
    double("protocol_binding").tap { |t| allow(t).to receive(:post).and_return({ "result" => result }) }
  end

  describe "#execute" do
    it "returns the updated Task" do
      result = described_class.new(id: "task-1").execute(protocol_binding_returning(task_hash))

      expect(result).to be_a(A2A::Task)
      expect(result.status.state).to eq(A2A::Task::State::CANCELED)
    end

    it "raises TaskNotCancelableError when the server rejects" do
      pb = double("protocol_binding")
      allow(pb).to receive(:post).and_return(
        { "error" => { "code" => -32002, "message" => "not cancelable" } }
      )

      expect { described_class.new(id: "task-1").execute(pb) }
        .to raise_error(A2A::TaskNotCancelableError)
    end
  end

  describe "#params" do
    it "sets id" do
      expect(described_class.new(id: "task-1").params).to eq("id" => "task-1")
    end

    it "includes metadata when provided" do
      params = described_class.new(id: "task-1", metadata: { "reason" => "user request" }).params

      expect(params["metadata"]).to eq("reason" => "user request")
    end

    it "omits nil optional fields" do
      expect(described_class.new(id: "task-1").params.keys).to eq(["id"])
    end
  end
end
