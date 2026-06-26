# frozen_string_literal: true

RSpec.describe A2A::Streaming::Response do
  let(:task)             { A2A::Task.new(id: "t1", context_id: "ctx1", status: A2A::Task::Status.new(state: A2A::Task::State::WORKING)) }
  let(:text_part)        { A2A::Part::Text.new(text: "hi") }
  let(:message)          { A2A::Message.new(id: "m1", role: A2A::Role::USER, parts: [text_part]) }
  let(:status_event)     { A2A::Streaming::StatusUpdateEvent.new(task_id: "t1", context_id: "ctx1", status: A2A::Task::Status.new(state: A2A::Task::State::WORKING)) }
  let(:artifact_event)   { A2A::Streaming::ArtifactUpdateEvent.new(task_id: "t1", context_id: "ctx1", artifact: A2A::Artifact.new(id: "a1", parts: [text_part])) }

  describe "#initialize" do
    it "stores type and payload for :task" do
      response = described_class.new(:task, task)

      expect(response.type).to eq :task
      expect(response.payload).to eq task
    end

    it "stores type and payload for :message" do
      response = described_class.new(:message, message)

      expect(response.type).to eq :message
      expect(response.payload).to eq message
    end

    it "stores type and payload for :status_update" do
      response = described_class.new(:status_update, status_event)

      expect(response.type).to eq :status_update
      expect(response.payload).to eq status_event
    end

    it "stores type and payload for :artifact_update" do
      response = described_class.new(:artifact_update, artifact_event)

      expect(response.type).to eq :artifact_update
      expect(response.payload).to eq artifact_event
    end

    it "raises ArgumentError for an unknown type" do
      expect { described_class.new(:bogus, task) }
        .to raise_error(ArgumentError, /unknown type: :bogus/)
    end

    it "raises TypeError when payload does not match the expected class" do
      expect { described_class.new(:task, message) }
        .to raise_error(TypeError, /payload must be a/)
    end
  end

  describe ".from_h" do
    it "builds a :task response" do
      hash = {
        "task" => {
          "id"        => "t1",
          "contextId" => "ctx1",
          "status"    => { "state" => A2A::Task::State::WORKING },
          "artifacts" => [],
          "history"   => []
        }
      }
      response = described_class.from_h(hash)

      expect(response.type).to eq :task
      expect(response.payload).to be_a(A2A::Task)
      expect(response.payload.id).to eq "t1"
    end

    it "builds a :message response" do
      hash = {
        "message" => { "messageId" => "m1", "role" => A2A::Role::USER, "parts" => [{ "text" => "hi" }] }
      }
      response = described_class.from_h(hash)

      expect(response.type).to eq :message
      expect(response.payload).to be_a(A2A::Message)
      expect(response.payload.id).to eq "m1"
    end

    it "builds a :status_update response" do
      hash = {
        "statusUpdate" => {
          "taskId"    => "t1",
          "contextId" => "ctx1",
          "status"    => { "state" => A2A::Task::State::WORKING }
        }
      }
      response = described_class.from_h(hash)

      expect(response.type).to eq :status_update
      expect(response.payload).to be_a(A2A::Streaming::StatusUpdateEvent)
      expect(response.payload.task_id).to eq "t1"
      expect(response.payload.context_id).to eq "ctx1"
    end

    it "builds an :artifact_update response" do
      hash = {
        "artifactUpdate" => {
          "taskId"    => "t1",
          "contextId" => "ctx1",
          "artifact"  => { "artifactId" => "a1", "parts" => [{ "text" => "result" }] }
        }
      }
      response = described_class.from_h(hash)

      expect(response.type).to eq :artifact_update
      expect(response.payload).to be_a(A2A::Streaming::ArtifactUpdateEvent)
      expect(response.payload.task_id).to eq "t1"
    end

    it "raises ArgumentError for an unrecognised hash" do
      expect { described_class.from_h("unknown" => {}) }
        .to raise_error(ArgumentError, /unrecognised StreamResponse keys/)
    end
  end

  describe "predicate methods" do
    it "#task? is true only for :task type" do
      expect(described_class.new(:task, task).task?).to be true
      expect(described_class.new(:message, message).task?).to be false
    end

    it "#message? is true only for :message type" do
      expect(described_class.new(:message, message).message?).to be true
      expect(described_class.new(:task, task).message?).to be false
    end

    it "#status_update? is true only for :status_update type" do
      expect(described_class.new(:status_update, status_event).status_update?).to be true
      expect(described_class.new(:task, task).status_update?).to be false
    end

    it "#artifact_update? is true only for :artifact_update type" do
      expect(described_class.new(:artifact_update, artifact_event).artifact_update?).to be true
      expect(described_class.new(:task, task).artifact_update?).to be false
    end
  end
end
