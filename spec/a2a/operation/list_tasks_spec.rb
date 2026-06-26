# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::ListTasks do
  def task_hash(id: "task-1")
    { "id" => id, "status" => { "state" => A2A::Task::State::COMPLETED }, "artifacts" => [], "history" => [] }
  end

  def response_hash(tasks: [])
    { "tasks" => tasks, "nextPageToken" => "", "pageSize" => 50, "totalSize" => tasks.length }
  end

  def protocol_binding_returning(result)
    double("protocol_binding").tap { |t| allow(t).to receive(:post).and_return({ "result" => result }) }
  end

  describe "#execute" do
    it "returns a ListTasks::Response" do
      op = described_class.new
      result = op.execute(protocol_binding_returning(response_hash(tasks: [task_hash])))

      expect(result).to be_a(described_class::Response)
      expect(result.tasks.length).to eq(1)
      expect(result.tasks.first).to be_a(A2A::Task)
    end

    it "exposes pagination fields" do
      result = described_class.new.execute(
        protocol_binding_returning(response_hash.merge("nextPageToken" => "tok", "totalSize" => 42))
      )

      expect(result.next_page_token).to eq("tok")
      expect(result.total_size).to eq(42)
    end

    it "raises an A2A error on JSON-RPC error" do
      pb = double("protocol_binding")
      allow(pb).to receive(:post).and_return(
        { "error" => { "code" => -32001, "message" => "not found" } }
      )

      expect { described_class.new.execute(pb) }.to raise_error(A2A::TaskNotFoundError)
    end
  end

  describe "#params" do
    it "returns empty hash when no filters set" do
      expect(described_class.new.params).to eq({})
    end

    it "serialises filters" do
      params = described_class.new(
        context_id: "ctx-1",
        status: A2A::Task::State::WORKING,
        page_size: 10,
        page_token: "tok",
        history_length: 3,
        include_artifacts: true,
        tenant: "acme"
      ).params

      expect(params).to eq(
        "contextId" => "ctx-1",
        "status" => A2A::Task::State::WORKING,
        "pageSize" => 10,
        "pageToken" => "tok",
        "historyLength" => 3,
        "includeArtifacts" => true,
        "tenant" => "acme"
      )
    end
  end

  describe "Response.from_h" do
    it "deserialises tasks and pagination" do
      response = described_class::Response.from_h(response_hash(tasks: [task_hash]))

      expect(response.tasks.first.id).to eq("task-1")
      expect(response.page_size).to eq(50)
    end
  end
end
