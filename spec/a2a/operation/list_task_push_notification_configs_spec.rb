# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Operation::ListTaskPushNotificationConfigs do
  def config_hash(id: "cfg-1")
    { "url" => "https://push.example.com", "id" => id, "taskId" => "task-1" }
  end

  def response_hash(configs: [])
    { "configs" => configs, "nextPageToken" => nil }
  end

  def protocol_binding_returning(result)
    double("protocol_binding").tap { |t| allow(t).to receive(:post).and_return({ "result" => result }) }
  end

  describe "#execute" do
    it "returns a ListTaskPushNotificationConfigs::Response" do
      op = described_class.new(task_id: "task-1")
      result = op.execute(protocol_binding_returning(response_hash(configs: [config_hash])))

      expect(result).to be_a(described_class::Response)
      expect(result.configs.length).to eq(1)
      expect(result.configs.first).to be_a(A2A::PushNotification::Config)
    end

    it "exposes next_page_token" do
      result = described_class.new(task_id: "task-1").execute(
        protocol_binding_returning(response_hash.merge("nextPageToken" => "tok"))
      )

      expect(result.next_page_token).to eq("tok")
    end
  end

  describe "#params" do
    it "sets taskId" do
      expect(described_class.new(task_id: "task-1").params).to eq("taskId" => "task-1")
    end

    it "includes pagination params when provided" do
      params = described_class.new(task_id: "task-1", page_size: 10, page_token: "tok").params

      expect(params["pageSize"]).to eq(10)
      expect(params["pageToken"]).to eq("tok")
    end
  end
end
