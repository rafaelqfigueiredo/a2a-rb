# frozen_string_literal: true

RSpec.describe A2A::Task do
  let(:status) { A2A::Task::Status.new(state: A2A::Task::State::WORKING) }

  describe "#initialize" do
    it "sets required attributes" do
      task = described_class.new(id: "t1", status: status)

      expect(task.id).to eq "t1"
      expect(task.status).to eq status
    end

    it "defaults optional attributes" do
      task = described_class.new(id: "t1", status: status)

      expect(task.context_id).to be_nil
      expect(task.artifacts).to be_nil
      expect(task.history).to be_nil
      expect(task.metadata).to be_nil
    end

    it "accepts all optional attributes" do
      msg      = A2A::Message.new(id: "m1", role: A2A::Role::USER, parts: [A2A::Part::Text.new(text: "hi")])
      artifact = A2A::Artifact.new(id: "a1", parts: [A2A::Part::Text.new(text: "result")])
      task = described_class.new(
        id: "t1",
        status: status,
        context_id: "ctx1",
        artifacts: [artifact],
        history: [msg],
        metadata: { "k" => "v" }
      )

      expect(task.context_id).to eq "ctx1"
      expect(task.artifacts).to eq [artifact]
      expect(task.history).to eq [msg]
      expect(task.metadata).to eq({ "k" => "v" })
    end

    it "raises TypeError when status is not a Task::Status" do
      expect { described_class.new(id: "t1", status: "invalid") }
        .to raise_error(TypeError, /status must be a Task::Status/)
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      task = described_class.from_h(
        "id" => "t1",
        "status" => { "state" => A2A::Task::State::SUBMITTED },
        "artifacts" => [],
        "history" => []
      )

      expect(task.id).to eq "t1"
      expect(task.status).to be_a(A2A::Task::Status)
      expect(task.status.state).to eq A2A::Task::State::SUBMITTED
    end

    it "builds history as Message objects" do
      task = described_class.from_h(
        "id" => "t1",
        "status" => { "state" => A2A::Task::State::WORKING },
        "artifacts" => [],
        "history" => [
          { "messageId" => "m1", "role" => A2A::Role::USER, "parts" => [{ "text" => "hi" }] }
        ]
      )

      expect(task.history.length).to eq 1
      expect(task.history.first).to be_a(A2A::Message)
      expect(task.history.first.id).to eq "m1"
    end

    it "builds artifacts as Artifact objects" do
      task = described_class.from_h(
        "id" => "t1",
        "status" => { "state" => A2A::Task::State::WORKING },
        "history" => [],
        "artifacts" => [
          { "artifactId" => "a1", "parts" => [{ "text" => "result" }] }
        ]
      )

      expect(task.artifacts.length).to eq 1
      expect(task.artifacts.first).to be_a(A2A::Artifact)
      expect(task.artifacts.first.id).to eq "a1"
    end

    it "defaults artifacts to empty array when absent from hash" do
      task = described_class.from_h(
        "id" => "t1",
        "status" => { "state" => A2A::Task::State::SUBMITTED },
        "artifacts" => [],
        "history" => []
      )

      expect(task.artifacts).to eq []
    end

    it "defaults history to empty array when absent from hash" do
      task = described_class.from_h(
        "id" => "t1",
        "status" => { "state" => A2A::Task::State::SUBMITTED },
        "artifacts" => [],
        "history" => []
      )

      expect(task.history).to eq []
    end

    it "sets context_id and metadata when present" do
      task = described_class.from_h(
        "id" => "t1",
        "status" => { "state" => A2A::Task::State::COMPLETED },
        "artifacts" => [],
        "history" => [],
        "contextId" => "ctx1",
        "metadata" => { "k" => "v" }
      )

      expect(task.context_id).to eq "ctx1"
      expect(task.metadata).to eq({ "k" => "v" })
    end

    it "raises KeyError when id is missing" do
      expect { described_class.from_h("status" => { "state" => A2A::Task::State::SUBMITTED }) }
        .to raise_error(KeyError)
    end

    it "raises KeyError when status is missing" do
      expect { described_class.from_h("id" => "t1") }
        .to raise_error(KeyError)
    end
  end

  describe ".from_h unknown keys" do
    it "ignores unrecognized fields" do
      task = described_class.from_h(
        "id" => "t1",
        "status" => { "state" => A2A::Task::State::SUBMITTED },
        "unknownField" => "ignored"
      )
      expect(task.id).to eq "t1"
    end
  end

  describe "#terminal?" do
    it "returns true for a terminal state" do
      task = described_class.new(id: "t1", status: A2A::Task::Status.new(state: A2A::Task::State::COMPLETED))

      expect(task.terminal?).to be true
    end

    it "returns false for a non-terminal state" do
      task = described_class.new(id: "t1", status: A2A::Task::Status.new(state: A2A::Task::State::WORKING))

      expect(task.terminal?).to be false
    end
  end

  describe "#to_h" do
    it "serializes all fields" do
      msg      = A2A::Message.new(id: "m1", role: A2A::Role::USER, parts: [A2A::Part::Text.new(text: "hi")])
      artifact = A2A::Artifact.new(id: "a1", parts: [A2A::Part::Text.new(text: "result")])
      task = described_class.new(
        id: "t1",
        status: status,
        context_id: "ctx1",
        artifacts: [artifact],
        history: [msg],
        metadata: { "k" => "v" }
      )

      result = task.to_h
      expect(result["id"]).to eq "t1"
      expect(result["contextId"]).to eq "ctx1"
      expect(result["status"]).to eq status.to_h
      expect(result["artifacts"]).to eq [artifact.to_h]
      expect(result["history"]).to eq [msg.to_h]
      expect(result["metadata"]).to eq({ "k" => "v" })
    end

    it "omits nil optional fields" do
      task = described_class.new(id: "t1", status: status)

      result = task.to_h
      expect(result).not_to have_key("contextId")
      expect(result).not_to have_key("artifacts")
      expect(result).not_to have_key("history")
      expect(result).not_to have_key("metadata")
    end

    it "round-trips through from_h" do
      task = described_class.new(id: "t1", status: status, context_id: "ctx1")
      restored = described_class.from_h(task.to_h)

      expect(restored.id).to eq task.id
      expect(restored.context_id).to eq task.context_id
      expect(restored.status.state).to eq task.status.state
    end
  end
end
