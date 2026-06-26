# frozen_string_literal: true

require "a2a"
require "webmock/rspec"

RSpec.describe A2A::Protocol::JsonRpc do
  let(:url) { "https://agent.example.com/rpc" }
  let(:protocol) { described_class.new(url: url) }

  describe "#initialize" do
    it "sets url" do
      expect(protocol.url).to eq(url)
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
    let(:transport) { instance_double(A2A::Protocol::JsonRpc::Transport) }
    let(:protocol) { described_class.new(url: url, transport: transport) }

    it "sends Content-Type, Accept, and A2A-Version" do
      allow(transport).to receive(:post) do |_url, body:, headers:|
        expect(headers["Content-Type"]).to eq("application/json")
        expect(headers["Accept"]).to eq("application/json")
        expect(headers["A2A-Version"]).to eq(A2A::Versioning::CURRENT)
        { "result" => {} }
      end

      protocol.post("GetTask", {})
    end

    it "merges caller-supplied extra headers" do
      p = described_class.new(url: url, headers: { "Authorization" => "Bearer tok" }, transport: transport)

      allow(transport).to receive(:post) do |_url, body:, headers:|
        expect(headers["Authorization"]).to eq("Bearer tok")
        { "result" => {} }
      end

      p.post("GetTask", {})
    end

    it "sends A2A-Extensions when extensions are configured" do
      p = described_class.new(url: url,
                              extensions: ["https://ext.example.com/v1", "https://ext.example.com/v2"],
                              transport: transport)

      allow(transport).to receive(:post) do |_url, body:, headers:|
        expect(headers["A2A-Extensions"]).to eq("https://ext.example.com/v1, https://ext.example.com/v2")
        { "result" => {} }
      end

      p.post("GetTask", {})
    end

    it "omits A2A-Extensions when no extensions are configured" do
      allow(transport).to receive(:post) do |_url, body:, headers:|
        expect(headers).not_to have_key("A2A-Extensions")
        { "result" => {} }
      end

      protocol.post("GetTask", {})
    end

    it "sends Accept: text/event-stream for stream calls" do
      allow(transport).to receive(:stream) do |_url, headers:, **|
        expect(headers["Accept"]).to eq("text/event-stream")
      end

      protocol.stream("SendStreamingMessage", {})
    end

    it "wraps the call in a JSON-RPC envelope" do
      allow(transport).to receive(:post) do |_url, body:, headers:|
        expect(body["jsonrpc"]).to eq("2.0")
        expect(body["method"]).to eq("GetTask")
        expect(body["params"]).to eq("id" => "t1")
        expect(body["id"]).to match(/\A[0-9a-f-]{36}\z/)
        { "result" => {} }
      end

      protocol.post("GetTask", "id" => "t1")
    end
  end

  describe "integration with A2A::Client" do
    let(:client) { A2A::Client.new(protocol: protocol) }

    let(:message) do
      A2A::Message.new(
        id: "msg-1",
        role: A2A::Role::USER,
        parts: [A2A::Part::Text.new(text: "hello")]
      )
    end

    let(:task_result) do
      {
        "jsonrpc" => "2.0",
        "id" => "req-1",
        "result" => {
          "task" => {
            "id" => "task-1",
            "status" => { "state" => A2A::Task::State::COMPLETED },
            "artifacts" => [],
            "history" => []
          }
        }
      }
    end

    describe "#send_message" do
      it "returns a Task when the server responds with a task" do
        stub_request(:post, url)
          .to_return(status: 200, body: task_result.to_json, headers: { "Content-Type" => "application/json" })

        result = client.send_message(message)

        expect(result).to be_a(A2A::Task)
        expect(result.id).to eq("task-1")
      end

      it "returns a Message when the server responds with a message" do
        body = {
          "jsonrpc" => "2.0",
          "id" => "req-1",
          "result" => {
            "message" => {
              "messageId" => "msg-2",
              "role" => A2A::Role::AGENT,
              "parts" => [{ "text" => "hi back" }]
            }
          }
        }

        stub_request(:post, url)
          .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })

        result = client.send_message(message)

        expect(result).to be_a(A2A::Message)
        expect(result.id).to eq("msg-2")
      end

      it "posts to the correct URL with the SendMessage method" do
        stub_request(:post, url)
          .to_return(status: 200, body: task_result.to_json, headers: { "Content-Type" => "application/json" })

        client.send_message(message)

        expect(WebMock).to have_requested(:post, url)
          .with { |req| JSON.parse(req.body)["method"] == "SendMessage" }
      end

      it "raises an A2A error when the server returns a JSON-RPC error" do
        body = { "jsonrpc" => "2.0", "id" => "req-1", "error" => { "code" => -32001, "message" => "not found" } }

        stub_request(:post, url)
          .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })

        expect { client.send_message(message) }.to raise_error(A2A::TaskNotFoundError, "not found")
      end
    end

    describe "#send_streaming_message" do
      def sse_line(result_hash)
        "data: #{JSON.generate({ "jsonrpc" => "2.0", "id" => "1", "result" => result_hash })}\n\n"
      end

      let(:task_sse) do
        sse_line("task" => {
          "id" => "task-1",
          "status" => { "state" => A2A::Task::State::WORKING },
          "artifacts" => [],
          "history" => []
        })
      end

      it "yields Streaming::Response events" do
        stub_request(:post, url)
          .to_return(status: 200, body: task_sse, headers: { "Content-Type" => "text/event-stream" })

        events = []
        client.send_streaming_message(message) { |e| events << e }

        expect(events.length).to eq(1)
        expect(events.first).to be_a(A2A::Streaming::Response)
        expect(events.first).to be_task
      end

      it "returns a Subscription when called without a block" do
        stub_request(:post, url)
          .to_return(status: 200, body: task_sse, headers: { "Content-Type" => "text/event-stream" })

        result = client.send_streaming_message(message)

        expect(result).to be_a(A2A::Streaming::Subscription)
      end

      it "posts to the correct URL with the SendStreamingMessage method" do
        stub_request(:post, url)
          .to_return(status: 200, body: task_sse, headers: { "Content-Type" => "text/event-stream" })

        client.send_streaming_message(message) { |_e| }

        expect(WebMock).to have_requested(:post, url)
          .with { |req| JSON.parse(req.body)["method"] == "SendStreamingMessage" }
      end
    end
  end
end
