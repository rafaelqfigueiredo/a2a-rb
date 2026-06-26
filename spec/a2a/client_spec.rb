# frozen_string_literal: true

require "a2a"

RSpec.describe A2A::Client do
  def build_card(interfaces, capabilities: nil)
    skill = A2A::AgentSkill.new(id: "s1", name: "Skill", description: "desc", tags: ["general"],
                                input_modes: ["text/plain"], output_modes: ["text/plain"])
    caps = capabilities ||
           A2A::AgentCapabilities.new(streaming: false, push_notifications: false, extended_agent_card: false)
    A2A::AgentCard.new(
      name: "Test", description: "desc", version: "1.0",
      supported_interfaces: interfaces,
      capabilities: caps,
      skills: [skill],
      default_input_modes: ["text/plain"],
      default_output_modes: ["text/plain"]
    )
  end

  def jsonrpc_iface(url: "https://agent.example.com/rpc")
    A2A::AgentInterface.new(url: url, protocol_binding: A2A::AgentInterface::JSONRPC, protocol_version: "1.0")
  end

  def http_json_iface(url: "https://agent.example.com")
    A2A::AgentInterface.new(url: url, protocol_binding: A2A::AgentInterface::HTTP_JSON, protocol_version: "1.0")
  end

  describe ".from_agent_card" do
    it "builds a Protocol::JsonRpc client when the first matching interface is JSONRPC" do
      client = described_class.from_agent_card(build_card([jsonrpc_iface]))

      expect(client).to be_a(described_class)
      expect(client.instance_variable_get(:@protocol)).to be_a(A2A::Protocol::JsonRpc)
    end

    it "builds a Protocol::HttpJson client when the first matching interface is HTTP+JSON" do
      client = described_class.from_agent_card(build_card([http_json_iface]))

      expect(client).to be_a(described_class)
      expect(client.instance_variable_get(:@protocol)).to be_a(A2A::Protocol::HttpJson)
    end

    it "respects the agent's declared interface order (first match wins)" do
      card = build_card([http_json_iface, jsonrpc_iface])
      client = described_class.from_agent_card(card)

      expect(client.instance_variable_get(:@protocol)).to be_a(A2A::Protocol::HttpJson)
    end

    it "accepts a caller-supplied preference order that overrides agent order" do
      card = build_card([http_json_iface, jsonrpc_iface])
      client = described_class.from_agent_card(card, preference: [A2A::AgentInterface::JSONRPC])

      expect(client.instance_variable_get(:@protocol)).to be_a(A2A::Protocol::JsonRpc)
    end

    it "raises UnsupportedOperationError when no interface matches the preference" do
      card = build_card([jsonrpc_iface])

      expect { described_class.from_agent_card(card, preference: [A2A::AgentInterface::GRPC]) }
        .to raise_error(A2A::UnsupportedOperationError, /no supported interface/)
    end

    it "raises VersionNotSupportedError when the matched interface has an unsupported version" do
      iface = A2A::AgentInterface.new(url: "https://agent.example.com/rpc",
                                      protocol_binding: A2A::AgentInterface::JSONRPC,
                                      protocol_version: "0.3")
      expect { described_class.from_agent_card(build_card([iface])) }
        .to raise_error(A2A::VersionNotSupportedError)
    end

    it "forwards headers and extensions to the protocol" do
      client = described_class.from_agent_card(
        build_card([jsonrpc_iface]),
        headers: { "Authorization" => "Bearer tok" },
        extensions: ["https://ext.example.com/v1"]
      )
      protocol = client.instance_variable_get(:@protocol)

      expect(protocol.headers).to eq("Authorization" => "Bearer tok")
      expect(protocol.extensions).to eq(["https://ext.example.com/v1"])
    end

    it "uses the interface URL as the protocol endpoint" do
      client = described_class.from_agent_card(build_card([jsonrpc_iface(url: "https://rpc.example.com/a2a")]))
      protocol = client.instance_variable_get(:@protocol)

      expect(protocol.url).to eq("https://rpc.example.com/a2a")
    end
  end

  describe "push notification capability guard" do
    let(:config) do
      A2A::PushNotification::Config.new(url: "https://client.example.com/hook", task_id: "t1")
    end

    context "when built from an AgentCard with pushNotifications: false" do
      let(:caps) do
        A2A::AgentCapabilities.new(streaming: false, push_notifications: false, extended_agent_card: false)
      end
      let(:card) { build_card([jsonrpc_iface], capabilities: caps) }
      let(:client) { described_class.from_agent_card(card) }

      it "raises PushNotificationNotSupportedError on create" do
        expect { client.create_task_push_notification_config(config) }
          .to raise_error(A2A::PushNotificationNotSupportedError)
      end

      it "raises PushNotificationNotSupportedError on get" do
        expect { client.get_task_push_notification_config(task_id: "t1", id: "c1") }
          .to raise_error(A2A::PushNotificationNotSupportedError)
      end

      it "raises PushNotificationNotSupportedError on list" do
        expect { client.list_task_push_notification_configs(task_id: "t1") }
          .to raise_error(A2A::PushNotificationNotSupportedError)
      end

      it "raises PushNotificationNotSupportedError on delete" do
        expect { client.delete_task_push_notification_config(task_id: "t1", id: "c1") }
          .to raise_error(A2A::PushNotificationNotSupportedError)
      end
    end

    context "when built from an AgentCard with pushNotifications: true" do
      let(:caps) do
        A2A::AgentCapabilities.new(streaming: false, push_notifications: true, extended_agent_card: false)
      end
      let(:card) { build_card([jsonrpc_iface], capabilities: caps) }
      let(:protocol_double) { instance_double(A2A::Protocol::JsonRpc) }
      let(:client) do
        c = described_class.from_agent_card(card)
        c.instance_variable_set(:@protocol, protocol_double)
        c
      end

      it "does not raise and calls through to the operation" do
        allow(protocol_double).to receive(:post).and_return(
          { "result" => { "url" => "https://client.example.com/hook", "taskId" => "t1" } }
        )

        expect { client.create_task_push_notification_config(config) }.not_to raise_error
      end
    end

    context "when built directly with Client.new (no capabilities)" do
      let(:protocol_double) { instance_double(A2A::Protocol::JsonRpc) }
      let(:client) { described_class.new(protocol: protocol_double) }

      it "does not raise — no capability info available" do
        allow(protocol_double).to receive(:post).and_return(
          { "result" => { "url" => "https://client.example.com/hook", "taskId" => "t1" } }
        )

        expect { client.create_task_push_notification_config(config) }.not_to raise_error
      end
    end
  end

  describe "extended agent card capability guard" do
    context "when built from an AgentCard with extendedAgentCard: false" do
      let(:caps) do
        A2A::AgentCapabilities.new(streaming: false, push_notifications: false, extended_agent_card: false)
      end
      let(:client) { described_class.from_agent_card(build_card([jsonrpc_iface], capabilities: caps)) }

      it "raises ExtendedAgentCardNotConfiguredError" do
        expect { client.get_extended_agent_card }
          .to raise_error(A2A::ExtendedAgentCardNotConfiguredError)
      end
    end

    context "when built from an AgentCard with extendedAgentCard: true" do
      let(:caps) do
        A2A::AgentCapabilities.new(streaming: false, push_notifications: false, extended_agent_card: true)
      end
      let(:protocol_double) { instance_double(A2A::Protocol::JsonRpc) }
      let(:client) do
        c = described_class.from_agent_card(build_card([jsonrpc_iface], capabilities: caps))
        c.instance_variable_set(:@protocol, protocol_double)
        c
      end

      it "does not raise and calls through to the operation" do
        card_hash = {
          "name" => "Agent", "description" => "d", "version" => "1.0",
          "capabilities" => { "streaming" => false, "pushNotifications" => false },
          "defaultInputModes" => ["text/plain"], "defaultOutputModes" => ["text/plain"],
          "skills" => [{ "id" => "s1", "name" => "S", "description" => "d",
                         "tags" => ["t"], "inputModes" => ["text/plain"],
                         "outputModes" => ["text/plain"] }],
          "supportedInterfaces" => [{ "url" => "https://agent.example.com/rpc",
                                      "protocolBinding" => "JSONRPC",
                                      "protocolVersion" => "1.0" }]
        }
        allow(protocol_double).to receive(:post).and_return({ "result" => card_hash })

        expect { client.get_extended_agent_card }.not_to raise_error
      end
    end

    context "when built directly with Client.new (no capabilities)" do
      let(:protocol_double) { instance_double(A2A::Protocol::JsonRpc) }
      let(:client) { described_class.new(protocol: protocol_double) }

      it "does not raise — no capability info available" do
        card_hash = {
          "name" => "Agent", "description" => "d", "version" => "1.0",
          "capabilities" => { "streaming" => false, "pushNotifications" => false },
          "defaultInputModes" => ["text/plain"], "defaultOutputModes" => ["text/plain"],
          "skills" => [{ "id" => "s1", "name" => "S", "description" => "d",
                         "tags" => ["t"], "inputModes" => ["text/plain"],
                         "outputModes" => ["text/plain"] }],
          "supportedInterfaces" => [{ "url" => "https://agent.example.com/rpc",
                                      "protocolBinding" => "JSONRPC",
                                      "protocolVersion" => "1.0" }]
        }
        allow(protocol_double).to receive(:post).and_return({ "result" => card_hash })

        expect { client.get_extended_agent_card }.not_to raise_error
      end
    end
  end

  let(:protocol) { instance_double(A2A::Protocol::JsonRpc) }
  let(:client) { described_class.new(protocol: protocol) }
  let(:message) do
    A2A::Message.new(
      id: "msg-1",
      role: A2A::Role::USER,
      parts: [A2A::Part::Text.new(text: "hello")]
    )
  end

  def task_result(state: A2A::Task::State::COMPLETED)
    task = { "id" => "task-1", "status" => { "state" => state }, "artifacts" => [], "history" => [] }
    { "result" => { "task" => task } }
  end

  describe "#send_message" do
    it "returns a Task" do
      allow(protocol).to receive(:post).and_return(task_result)

      result = client.send_message(message)

      expect(result).to be_a(A2A::Task)
      expect(result.id).to eq("task-1")
    end

    it "returns a Message" do
      allow(protocol).to receive(:post).and_return(
        { "result" => { "message" => { "messageId" => "msg-2", "role" => A2A::Role::AGENT,
                                       "parts" => [{ "text" => "hi" }] } } }
      )

      result = client.send_message(message)

      expect(result).to be_a(A2A::Message)
    end

    it "calls post with the SendMessage method name" do
      allow(protocol).to receive(:post) do |method, _params|
        expect(method).to eq("SendMessage")
        task_result
      end

      client.send_message(message)
    end
  end

  describe "#send_streaming_message" do
    it "calls stream with the SendStreamingMessage method name" do
      allow(protocol).to receive(:stream) do |method, _params|
        expect(method).to eq("SendStreamingMessage")
      end

      client.send_streaming_message(message) { nil }
    end
  end

  describe "#cancel_task" do
    def terminal_task(state: A2A::Task::State::COMPLETED)
      A2A::Task.new(id: "task-1", status: A2A::Task::Status.new(state: state))
    end

    def working_task
      A2A::Task.new(id: "task-1", status: A2A::Task::Status.new(state: A2A::Task::State::WORKING))
    end

    it "raises TaskNotCancelableError when passed a terminal Task object" do
      A2A::Task::State::TERMINAL.each do |state|
        expect { client.cancel_task(terminal_task(state: state)) }
          .to raise_error(A2A::TaskNotCancelableError, /terminal/)
      end
    end

    it "calls through to the operation when passed a non-terminal Task object" do
      allow(protocol).to receive(:post).and_return(
        { "result" => { "id" => "task-1", "status" => { "state" => A2A::Task::State::CANCELED } } }
      )

      expect { client.cancel_task(working_task) }.not_to raise_error
    end

    it "extracts the id from a Task object when calling through" do
      received_params = nil
      allow(protocol).to receive(:post) do |_method, params|
        received_params = params
        { "result" => { "id" => "task-1", "status" => { "state" => A2A::Task::State::CANCELED } } }
      end

      client.cancel_task(working_task)

      expect(received_params["id"]).to eq("task-1")
    end

    it "accepts a plain string id and calls through" do
      allow(protocol).to receive(:post).and_return(
        { "result" => { "id" => "task-1", "status" => { "state" => A2A::Task::State::CANCELED } } }
      )

      expect { client.cancel_task("task-1") }.not_to raise_error
    end
  end
end
