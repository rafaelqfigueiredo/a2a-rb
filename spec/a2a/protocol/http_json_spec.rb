# frozen_string_literal: true

require "a2a"
require "webmock/rspec"

RSpec.describe A2A::Protocol::HttpJson do
  let(:url) { "https://agent.example.com" }
  let(:protocol) { described_class.new(url: url) }

  describe "#initialize" do
    it "sets url (trailing slash stripped)" do
      expect(described_class.new(url: "https://agent.example.com/").url).to eq("https://agent.example.com")
    end

    it "defaults version to the current spec version" do
      expect(protocol.version).to eq(A2A::Versioning::CURRENT)
    end

    it "defaults headers to empty hash" do
      expect(protocol.headers).to eq({})
    end

    it "defaults extensions to empty array" do
      expect(protocol.extensions).to eq([])
    end

    it "accepts a custom version" do
      p = described_class.new(url: url, version: "0.9")
      expect(p.version).to eq("0.9")
    end

    it "accepts extra headers" do
      p = described_class.new(url: url, headers: { "Authorization" => "Bearer tok" })
      expect(p.headers).to eq("Authorization" => "Bearer tok")
    end

    it "accepts extensions" do
      p = described_class.new(url: url, extensions: ["https://ext.example.com/v1"])
      expect(p.extensions).to eq(["https://ext.example.com/v1"])
    end
  end

  describe "headers forwarded to transport" do
    let(:transport) { instance_double(A2A::Protocol::HttpJson::Transport) }
    let(:protocol) { described_class.new(url: url, transport: transport) }

    it "sends Content-Type, Accept, and A2A-Version on POST" do
      allow(transport).to receive(:post) do |_url, body: nil, headers:|
        expect(headers["Content-Type"]).to eq("application/json")
        expect(headers["Accept"]).to eq("application/json")
        expect(headers["A2A-Version"]).to eq(A2A::Versioning::CURRENT)
        {}
      end

      protocol.post("/tasks", body: {})
    end

    it "merges extra headers" do
      p = described_class.new(url: url, headers: { "Authorization" => "Bearer tok" }, transport: transport)

      allow(transport).to receive(:get) do |_url, query: nil, headers:|
        expect(headers["Authorization"]).to eq("Bearer tok")
        {}
      end

      p.get("/tasks/t1")
    end

    it "sends A2A-Extensions when configured" do
      p = described_class.new(url: url,
                              extensions: ["https://ext.example.com/v1"],
                              transport: transport)

      allow(transport).to receive(:get) do |_url, query: nil, headers:|
        expect(headers["A2A-Extensions"]).to eq("https://ext.example.com/v1")
        {}
      end

      p.get("/tasks/t1")
    end

    it "omits A2A-Extensions when no extensions are configured" do
      allow(transport).to receive(:get) do |_url, query: nil, headers:|
        expect(headers).not_to have_key("A2A-Extensions")
        {}
      end

      protocol.get("/tasks/t1")
    end

    it "sends Accept: text/event-stream for stream calls" do
      allow(transport).to receive(:stream) do |_url, headers:, **|
        expect(headers["Accept"]).to eq("text/event-stream")
      end

      protocol.stream("/message:stream", method: :post, body: {})
    end

    it "prepends the base URL to paths" do
      allow(transport).to receive(:get) do |full_url, query: nil, headers: nil|
        expect(full_url).to eq("#{url}/tasks/t1")
        {}
      end

      protocol.get("/tasks/t1")
    end
  end

  describe "integration with A2A::Client" do
    let(:client) { A2A::Client.new(protocol: protocol) }

    let(:task_body) do
      {
        "id" => "task-1",
        "status" => { "state" => A2A::Task::State::COMPLETED },
        "artifacts" => [],
        "history" => []
      }
    end

    let(:message) do
      A2A::Message.new(
        id: "msg-1",
        role: A2A::Role::USER,
        parts: [A2A::Part::Text.new(text: "hello")]
      )
    end

    describe "#send_message — POST /message:send" do
      it "returns a Task" do
        stub_request(:post, "#{url}/message:send")
          .to_return(status: 200, body: { "task" => task_body }.to_json,
                     headers: { "Content-Type" => "application/json" })

        result = client.send_message(message)

        expect(result).to be_a(A2A::Task)
        expect(result.id).to eq("task-1")
      end

      it "returns a Message when the server responds with a message" do
        stub_request(:post, "#{url}/message:send")
          .to_return(status: 200,
                     body: { "message" => { "messageId" => "msg-2", "role" => A2A::Role::AGENT,
                                            "parts" => [{ "text" => "hi" }] } }.to_json,
                     headers: { "Content-Type" => "application/json" })

        result = client.send_message(message)

        expect(result).to be_a(A2A::Message)
      end
    end

    describe "#get_task — GET /tasks/:id" do
      it "returns a Task" do
        stub_request(:get, "#{url}/tasks/task-1")
          .to_return(status: 200, body: task_body.to_json,
                     headers: { "Content-Type" => "application/json" })

        result = client.get_task("task-1")

        expect(result).to be_a(A2A::Task)
        expect(result.id).to eq("task-1")
      end

      it "passes historyLength as a query param" do
        stub_request(:get, "#{url}/tasks/task-1")
          .with(query: { "historyLength" => "5" })
          .to_return(status: 200, body: task_body.to_json,
                     headers: { "Content-Type" => "application/json" })

        client.get_task("task-1", history_length: 5)
      end
    end

    describe "#cancel_task — POST /tasks/:id:cancel" do
      it "returns the updated Task" do
        stub_request(:post, "#{url}/tasks/task-1:cancel")
          .to_return(status: 200,
                     body: task_body.merge("status" => { "state" => A2A::Task::State::CANCELED }).to_json,
                     headers: { "Content-Type" => "application/json" })

        result = client.cancel_task("task-1")

        expect(result).to be_a(A2A::Task)
      end
    end

    describe "#list_tasks — GET /tasks" do
      it "returns a ListTasks::Response" do
        stub_request(:get, "#{url}/tasks")
          .to_return(status: 200,
                     body: { "tasks" => [task_body], "nextPageToken" => nil,
                             "pageSize" => 10, "totalSize" => 1 }.to_json,
                     headers: { "Content-Type" => "application/json" })

        result = client.list_tasks

        expect(result).to be_a(A2A::Operation::ListTasks::Response)
        expect(result.tasks.length).to eq(1)
      end
    end

    describe "#get_extended_agent_card — GET /extendedAgentCard" do
      let(:card_body) do
        {
          "name" => "Test Agent",
          "description" => "desc",
          "version" => "1.0",
          "url" => "https://agent.example.com",
          "capabilities" => { "streaming" => false, "pushNotifications" => false },
          "defaultInputModes" => ["text/plain"],
          "defaultOutputModes" => ["text/plain"],
          "skills" => [{ "id" => "s1", "name" => "Skill One", "description" => "does stuff",
                         "tags" => ["general"], "inputModes" => ["text/plain"], "outputModes" => ["text/plain"] }],
          "supportedInterfaces" => [{ "url" => "https://agent.example.com/rpc",
                                      "protocolBinding" => "JSONRPC", "protocolVersion" => "1.0" }]
        }
      end

      it "returns an AgentCard" do
        stub_request(:get, "#{url}/extendedAgentCard")
          .to_return(status: 200, body: card_body.to_json,
                     headers: { "Content-Type" => "application/json" })

        result = client.get_extended_agent_card

        expect(result).to be_a(A2A::AgentCard)
        expect(result.name).to eq("Test Agent")
      end
    end

    describe "#delete_task_push_notification_config — DELETE /tasks/:id/pushNotificationConfigs/:config_id" do
      it "returns nil" do
        stub_request(:delete, "#{url}/tasks/task-1/pushNotificationConfigs/cfg-1")
          .to_return(status: 204)

        result = client.delete_task_push_notification_config(task_id: "task-1", id: "cfg-1")

        expect(result).to be_nil
      end
    end

    describe "#send_streaming_message — POST /message:stream" do
      def sse_event(result_hash)
        "data: #{JSON.generate({ 'jsonrpc' => '2.0', 'id' => '1', 'result' => result_hash })}\n\n"
      end

      let(:task_sse) do
        sse_event("task" => task_body.merge("status" => { "state" => A2A::Task::State::WORKING }))
      end

      it "yields Streaming::Response events" do
        stub_request(:post, "#{url}/message:stream")
          .to_return(status: 200, body: task_sse, headers: { "Content-Type" => "text/event-stream" })

        events = []
        client.send_streaming_message(message) { |e| events << e }

        expect(events.length).to eq(1)
        expect(events.first).to be_task
      end

      it "returns a Subscription when called without a block" do
        stub_request(:post, "#{url}/message:stream")
          .to_return(status: 200, body: task_sse, headers: { "Content-Type" => "text/event-stream" })

        result = client.send_streaming_message(message)

        expect(result).to be_a(A2A::Streaming::Subscription)
      end
    end
  end
end
