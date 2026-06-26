# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Task, "#transition_to" do
  let(:task) do
    A2A::Task.new(
      id: "t1",
      context_id: "ctx-1",
      status: A2A::Task::Status.new(state: A2A::Task::State::SUBMITTED),
      artifacts: [],
      history: [],
      metadata: { "k" => "v" }
    )
  end

  it "returns a new Task with the updated state" do
    updated = task.transition_to(A2A::Task::State::WORKING)

    expect(updated).to be_a(A2A::Task)
    expect(updated.status.state).to eq(A2A::Task::State::WORKING)
  end

  it "preserves all other fields" do
    updated = task.transition_to(A2A::Task::State::WORKING)

    expect(updated.id).to eq("t1")
    expect(updated.context_id).to eq("ctx-1")
    expect(updated.artifacts).to eq([])
    expect(updated.metadata).to eq("k" => "v")
  end

  it "does not mutate the original task" do
    task.transition_to(A2A::Task::State::WORKING)

    expect(task.status.state).to eq(A2A::Task::State::SUBMITTED)
  end

  it "attaches an optional message and timestamp" do
    msg = A2A::Message.new(id: "m1", role: A2A::Role::AGENT, parts: [A2A::Part::Text.new(text: "done")])
    updated = task.transition_to(A2A::Task::State::COMPLETED, message: msg, timestamp: "2026-01-01T00:00:00Z")

    expect(updated.status.message).to eq(msg)
    expect(updated.status.timestamp).to eq("2026-01-01T00:00:00Z")
  end

  it "raises ArgumentError for an unknown state" do
    expect { task.transition_to("NONSENSE") }.to raise_error(ArgumentError, /unknown state/)
  end

  it "raises TaskNotCancelableError when already terminal" do
    terminal = task.transition_to(A2A::Task::State::COMPLETED)

    expect { terminal.transition_to(A2A::Task::State::WORKING) }
      .to raise_error(A2A::TaskNotCancelableError, /terminal state/)
  end
end
