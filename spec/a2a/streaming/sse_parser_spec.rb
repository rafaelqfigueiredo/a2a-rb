# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Streaming::SseParser do
  def sse_event(result_hash)
    "data: #{JSON.generate({ "jsonrpc" => "2.0", "id" => "1", "result" => result_hash })}\n\n"
  end

  def task_result
    { "task" => { "id" => "task-1", "status" => { "state" => A2A::Task::State::WORKING }, "artifacts" => [], "history" => [] } }
  end

  describe ".each" do
    it "yields a Streaming::Response for each event" do
      events = []
      described_class.each(StringIO.new(sse_event(task_result))) { |e| events << e }

      expect(events.length).to eq(1)
      expect(events.first).to be_a(A2A::Streaming::Response)
      expect(events.first).to be_task
    end

    it "handles multiple events" do
      status = { "statusUpdate" => { "taskId" => "t1", "contextId" => "c1", "status" => { "state" => A2A::Task::State::COMPLETED } } }
      body = sse_event(task_result) + sse_event(status)
      events = []
      described_class.each(StringIO.new(body)) { |e| events << e }

      expect(events.length).to eq(2)
      expect(events.first).to be_task
      expect(events.last).to be_status_update
    end

    it "assembles multi-line data fields into one event" do
      # SSE spec: multiple data: lines are concatenated with LF before parsing.
      # Split at a JSON whitespace boundary so the concatenated result is valid.
      part1 = '{"jsonrpc":"2.0","id":"1",'
      part2 = '"result":{"task":{"id":"task-1","status":{"state":"TASK_STATE_WORKING"},"artifacts":[],"history":[]}}}'
      body = "data: #{part1}\ndata: #{part2}\n\n"
      events = []
      described_class.each(StringIO.new(body)) { |e| events << e }

      expect(events.length).to eq(1)
      expect(events.first).to be_task
    end

    it "skips non-data SSE fields" do
      body = "event: update\nid: 1\n" + sse_event(task_result)
      events = []
      described_class.each(StringIO.new(body)) { |e| events << e }

      expect(events.length).to eq(1)
    end

    it "skips the [DONE] sentinel" do
      body = sse_event(task_result) + "data: [DONE]\n\n"
      events = []
      described_class.each(StringIO.new(body)) { |e| events << e }

      expect(events.length).to eq(1)
    end

    it "raises an A2A error when the envelope contains a JSON-RPC error" do
      body = "data: #{JSON.generate({ "error" => { "code" => -32001, "message" => "not found" } })}\n\n"

      expect { described_class.each(StringIO.new(body)) { |_e| } }
        .to raise_error(A2A::TaskNotFoundError, "not found")
    end
  end
end
