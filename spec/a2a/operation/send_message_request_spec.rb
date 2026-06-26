# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::SendMessageRequest do
  let(:message_h) do
    { "messageId" => "m1", "role" => A2A::Role::USER, "parts" => [{ "text" => "hello" }] }
  end

  describe ".from_h" do
    it "deserialises message" do
      req = described_class.from_h({ "message" => message_h })

      expect(req.message).to be_a(A2A::Message)
      expect(req.message.id).to eq("m1")
    end

    it "deserialises configuration when present" do
      hash = {
        "message" => message_h,
        "configuration" => { "historyLength" => 5, "returnImmediately" => true }
      }
      req = described_class.from_h(hash)

      expect(req.configuration).to be_a(A2A::Operation::SendMessage::Configuration)
      expect(req.configuration.history_length).to eq(5)
      expect(req.configuration.return_immediately).to eq(true)
    end

    it "defaults to an empty Configuration when absent" do
      req = described_class.from_h({ "message" => message_h })

      expect(req.configuration).to be_a(A2A::Operation::SendMessage::Configuration)
    end

    it "captures metadata and tenant" do
      hash = { "message" => message_h, "metadata" => { "trace" => "x" }, "tenant" => "acme" }
      req = described_class.from_h(hash)

      expect(req.metadata).to eq("trace" => "x")
      expect(req.tenant).to eq("acme")
    end

    it "raises KeyError when message is missing" do
      expect { described_class.from_h({}) }.to raise_error(KeyError)
    end
  end
end
