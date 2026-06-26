# frozen_string_literal: true

RSpec.describe A2A::Task::Status do
  describe "#initialize" do
    it "sets state and defaults optional attributes" do
      status = described_class.new(state: A2A::Task::State::WORKING)

      expect(status.state).to eq A2A::Task::State::WORKING
      expect(status.message).to be_nil
      expect(status.timestamp).to be_nil
    end

    it "sets all attributes" do
      msg = A2A::Message.new(id: "m1", role: A2A::Role::USER, parts: [A2A::Part::Text.new(text: "hi")])
      status = described_class.new(
        state:     A2A::Task::State::COMPLETED,
        message:   msg,
        timestamp: "2026-06-18T00:00:00Z"
      )

      expect(status.message).to eq msg
      expect(status.timestamp).to eq "2026-06-18T00:00:00Z"
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      status = described_class.from_h("state" => A2A::Task::State::SUBMITTED)

      expect(status.state).to eq A2A::Task::State::SUBMITTED
      expect(status.message).to be_nil
      expect(status.timestamp).to be_nil
    end

    it "builds a nested message when present" do
      status = described_class.from_h(
        "state"   => A2A::Task::State::WORKING,
        "message" => { "messageId" => "m1", "role" => A2A::Role::AGENT, "parts" => [{ "text" => "hi" }] }
      )

      expect(status.message).to be_a(A2A::Message)
      expect(status.message.id).to eq "m1"
    end

    it "sets timestamp when present" do
      status = described_class.from_h(
        "state"     => A2A::Task::State::COMPLETED,
        "timestamp" => "2026-06-18T00:00:00Z"
      )

      expect(status.timestamp).to eq "2026-06-18T00:00:00Z"
    end

    it "raises KeyError when state is missing" do
      expect { described_class.from_h({}) }.to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "omits nil optional fields" do
      status = described_class.new(state: A2A::Task::State::SUBMITTED)

      result = status.to_h
      expect(result["state"]).to eq A2A::Task::State::SUBMITTED
      expect(result).not_to have_key("message")
      expect(result).not_to have_key("timestamp")
    end

    it "serializes all present fields" do
      msg = A2A::Message.new(id: "m1", role: A2A::Role::USER, parts: [A2A::Part::Text.new(text: "hi")])
      status = described_class.new(
        state:     A2A::Task::State::COMPLETED,
        message:   msg,
        timestamp: "2026-06-18T00:00:00Z"
      )

      result = status.to_h
      expect(result["state"]).to eq A2A::Task::State::COMPLETED
      expect(result["message"]).to eq msg.to_h
      expect(result["timestamp"]).to eq "2026-06-18T00:00:00Z"
    end
  end

  describe "#terminal?" do
    it "returns true for terminal states" do
      [
        A2A::Task::State::COMPLETED,
        A2A::Task::State::FAILED,
        A2A::Task::State::CANCELED,
        A2A::Task::State::REJECTED
      ].each do |state|
        expect(described_class.new(state: state).terminal?).to be true
      end
    end

    it "returns false for non-terminal states" do
      [
        A2A::Task::State::SUBMITTED,
        A2A::Task::State::WORKING,
        A2A::Task::State::INPUT_REQUIRED,
        A2A::Task::State::AUTH_REQUIRED
      ].each do |state|
        expect(described_class.new(state: state).terminal?).to be false
      end
    end
  end
end
