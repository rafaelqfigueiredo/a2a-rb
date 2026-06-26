# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::SendMessage::Configuration do
  describe ".from_h" do
    it "maps camelCase keys to attributes" do
      config = described_class.from_h(
        "acceptedOutputModes" => ["text/plain"],
        "historyLength" => 3,
        "returnImmediately" => true
      )

      expect(config.accepted_output_modes).to eq(["text/plain"])
      expect(config.history_length).to eq(3)
      expect(config.return_immediately).to be(true)
    end

    it "leaves unset attributes nil" do
      config = described_class.from_h({})

      expect(config.accepted_output_modes).to be_nil
      expect(config.history_length).to be_nil
      expect(config.return_immediately).to be_nil
      expect(config.task_push_notification_config).to be_nil
    end
  end

  describe "#to_h" do
    it "returns an empty hash when nothing is set" do
      expect(described_class.new.to_h).to eq({})
    end

    it "serialises accepted_output_modes" do
      config = described_class.new(accepted_output_modes: ["text/plain"])

      expect(config.to_h).to eq("acceptedOutputModes" => ["text/plain"])
    end

    it "serialises history_length" do
      expect(described_class.new(history_length: 5).to_h).to eq("historyLength" => 5)
    end

    it "serialises return_immediately when true" do
      expect(described_class.new(return_immediately: true).to_h).to eq("returnImmediately" => true)
    end

    it "serialises return_immediately when false" do
      expect(described_class.new(return_immediately: false).to_h).to eq("returnImmediately" => false)
    end

    it "serialises a PushNotification::Config object to a hash" do
      push = A2A::PushNotification::Config.new(url: "https://push.example.com")
      config = described_class.new(task_push_notification_config: push)

      expect(config.to_h["taskPushNotificationConfig"]).to include("url" => "https://push.example.com")
    end

    it "omits nil fields" do
      config = described_class.new(history_length: 2)

      expect(config.to_h.keys).to eq(["historyLength"])
    end
  end
end
