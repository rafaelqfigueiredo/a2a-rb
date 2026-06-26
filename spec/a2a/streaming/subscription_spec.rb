# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Streaming::Subscription do
  def sse_event(result_hash)
    "data: #{JSON.generate({ 'jsonrpc' => '2.0', 'id' => '1', 'result' => result_hash })}\n\n"
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

  describe "#each" do
    it "yields all events when no terminal event is present" do
      body = sse_event(task_result) + sse_event(task_result)
      events = described_class.new(StringIO.new(body)).to_a

      expect(events.length).to eq(2)
    end

    it "stops after a status update with final: true" do
      body = sse_event(task_result) +
             sse_event(status_update_result(final: true)) +
             sse_event(task_result)
      events = described_class.new(StringIO.new(body)).to_a

      expect(events.length).to eq(2)
      expect(events.last).to be_status_update
    end

    it "stops after a terminal task state in a status update" do
      body = sse_event(task_result) +
             sse_event(status_update_result(state: A2A::Task::State::COMPLETED)) +
             sse_event(task_result)
      events = described_class.new(StringIO.new(body)).to_a

      expect(events.length).to eq(2)
    end

    it "stops after a terminal task snapshot" do
      body = sse_event(task_result) +
             sse_event(task_result(state: A2A::Task::State::COMPLETED)) +
             sse_event(task_result)
      events = described_class.new(StringIO.new(body)).to_a

      expect(events.length).to eq(2)
      expect(events.last.type).to eq(:task)
    end

    it "does not stop on a non-terminal task snapshot" do
      body = sse_event(task_result) + sse_event(task_result)
      events = described_class.new(StringIO.new(body)).to_a

      expect(events.length).to eq(2)
    end

    it "returns an Enumerator when called without a block" do
      sub = described_class.new(StringIO.new(sse_event(task_result)))

      expect(sub.each).to be_a(Enumerator)
    end

    it "includes Enumerable — map works" do
      body = sse_event(task_result)
      types = described_class.new(StringIO.new(body)).map(&:type)

      expect(types).to eq([:task])
    end
  end
end
