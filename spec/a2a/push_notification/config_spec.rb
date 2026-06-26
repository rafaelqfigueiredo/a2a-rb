# frozen_string_literal: true

RSpec.describe A2A::PushNotification::Config do
  let(:auth) { A2A::PushNotification::AuthenticationInfo.new(scheme: "Bearer") }

  describe "#initialize" do
    it "sets required url" do
      config = described_class.new(url: "https://example.com/hook")

      expect(config.url).to eq "https://example.com/hook"
    end

    it "defaults all optional attributes to nil" do
      config = described_class.new(url: "https://example.com/hook")

      expect(config.id).to be_nil
      expect(config.token).to be_nil
      expect(config.tenant).to be_nil
      expect(config.task_id).to be_nil
      expect(config.authentication).to be_nil
    end

    it "accepts all optional attributes" do
      config = described_class.new(
        url:            "https://example.com/hook",
        id:             "cfg-1",
        token:          "tok-abc",
        tenant:         "tenant-x",
        task_id:        "task-1",
        authentication: auth
      )

      expect(config.id).to eq "cfg-1"
      expect(config.token).to eq "tok-abc"
      expect(config.tenant).to eq "tenant-x"
      expect(config.task_id).to eq "task-1"
      expect(config.authentication).to eq auth
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      config = described_class.from_h("url" => "https://example.com/hook")

      expect(config.url).to eq "https://example.com/hook"
      expect(config.id).to be_nil
      expect(config.token).to be_nil
      expect(config.tenant).to be_nil
      expect(config.task_id).to be_nil
      expect(config.authentication).to be_nil
    end

    it "maps taskId to task_id" do
      config = described_class.from_h("url" => "https://example.com/hook", "taskId" => "task-1")

      expect(config.task_id).to eq "task-1"
    end

    it "deserializes a nested authentication object" do
      config = described_class.from_h(
        "url"            => "https://example.com/hook",
        "authentication" => { "scheme" => "Bearer" }
      )

      expect(config.authentication).to be_a(A2A::PushNotification::AuthenticationInfo)
      expect(config.authentication.scheme).to eq "Bearer"
    end

    it "deserializes all fields" do
      config = described_class.from_h(
        "url"    => "https://example.com/hook",
        "id"     => "cfg-1",
        "token"  => "tok-abc",
        "tenant" => "tenant-x",
        "taskId" => "task-1"
      )

      expect(config.id).to eq "cfg-1"
      expect(config.token).to eq "tok-abc"
      expect(config.tenant).to eq "tenant-x"
      expect(config.task_id).to eq "task-1"
    end

    it "raises KeyError when url is missing" do
      expect { described_class.from_h("id" => "cfg-1") }
        .to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serializes all present fields with protocol key names" do
      config = described_class.new(
        url:     "https://example.com/hook",
        id:      "cfg-1",
        token:   "tok-abc",
        tenant:  "tenant-x",
        task_id: "task-1"
      )

      result = config.to_h
      expect(result["url"]).to eq "https://example.com/hook"
      expect(result["id"]).to eq "cfg-1"
      expect(result["token"]).to eq "tok-abc"
      expect(result["tenant"]).to eq "tenant-x"
      expect(result["taskId"]).to eq "task-1"
    end

    it "includes nil fields" do
      config = described_class.new(url: "https://example.com/hook")

      result = config.to_h
      expect(result["url"]).to eq "https://example.com/hook"
      expect(result["id"]).to be_nil
      expect(result["token"]).to be_nil
      expect(result["tenant"]).to be_nil
      expect(result["taskId"]).to be_nil
      expect(result["authentication"]).to be_nil
    end
  end
end
