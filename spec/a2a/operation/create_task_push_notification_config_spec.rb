# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::CreateTaskPushNotificationConfig do
  let(:config) { A2A::PushNotification::Config.new(url: "https://push.example.com", task_id: "task-1") }

  def config_hash
    { "url" => "https://push.example.com", "id" => "cfg-1", "taskId" => "task-1" }
  end

  def protocol_binding_returning(result)
    double("protocol_binding").tap { |t| allow(t).to receive(:post).and_return({ "result" => result }) }
  end

  describe "#execute" do
    it "returns a PushNotification::Config" do
      result = described_class.new(config).execute(protocol_binding_returning(config_hash))

      expect(result).to be_a(A2A::PushNotification::Config)
      expect(result.id).to eq("cfg-1")
      expect(result.url).to eq("https://push.example.com")
    end

    it "raises on JSON-RPC error" do
      pb = double("protocol_binding")
      allow(pb).to receive(:post).and_return(
        { "error" => { "code" => -32003, "message" => "push not supported" } }
      )

      expect { described_class.new(config).execute(pb) }
        .to raise_error(A2A::PushNotificationNotSupportedError)
    end
  end

  describe "#params" do
    it "nests the config under pushNotificationConfig" do
      params = described_class.new(config).params

      expect(params["pushNotificationConfig"]).to include("url" => "https://push.example.com")
    end

    it "accepts a raw hash" do
      params = described_class.new({ "url" => "https://push.example.com" }).params

      expect(params["pushNotificationConfig"]["url"]).to eq("https://push.example.com")
    end

    it "includes tenant when provided" do
      params = described_class.new(config, tenant: "acme").params

      expect(params["tenant"]).to eq("acme")
    end
  end
end
