# frozen_string_literal: true

RSpec.describe A2A::Streaming::StatusUpdateEvent do
  let(:status) { A2A::Task::Status.new(state: A2A::Task::State::WORKING) }

  describe "#initialize" do
    it "sets required attributes" do
      event = described_class.new(context_id: "ctx1", task_id: "t1", status: status)

      expect(event.context_id).to eq "ctx1"
      expect(event.task_id).to eq "t1"
      expect(event.status).to eq status
    end

    it "defaults metadata to nil" do
      event = described_class.new(context_id: "ctx1", task_id: "t1", status: status)

      expect(event.metadata).to be_nil
    end

    it "accepts metadata" do
      event = described_class.new(
        context_id: "ctx1",
        task_id: "t1",
        status: status,
        metadata: { "k" => "v" }
      )

      expect(event.metadata).to eq({ "k" => "v" })
    end

    it "raises TypeError when status is not a Task::Status" do
      expect { described_class.new(context_id: "ctx1", task_id: "t1", status: "bad") }
        .to raise_error(TypeError, /status must be a Task::Status/)
    end
  end

  describe ".from_h" do
    it "builds from a full hash" do
      event = described_class.from_h(
        "taskId" => "t1",
        "contextId" => "ctx1",
        "status" => { "state" => A2A::Task::State::WORKING }
      )

      expect(event.task_id).to eq "t1"
      expect(event.context_id).to eq "ctx1"
      expect(event.status).to be_a(A2A::Task::Status)
      expect(event.status.state).to eq A2A::Task::State::WORKING
    end

    it "raises KeyError when taskId is missing" do
      expect do
        described_class.from_h("contextId" => "ctx1", "status" => { "state" => A2A::Task::State::WORKING })
      end.to raise_error(KeyError)
    end

    it "raises KeyError when contextId is missing" do
      expect do
        described_class.from_h("taskId" => "t1", "status" => { "state" => A2A::Task::State::WORKING })
      end.to raise_error(KeyError)
    end

    it "raises KeyError when status is missing" do
      expect { described_class.from_h("taskId" => "t1", "contextId" => "ctx1") }
        .to raise_error(KeyError)
    end
  end
end
