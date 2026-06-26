# frozen_string_literal: true

module A2A
  class Client
    SUPPORTED_BINDINGS = [AgentInterface::JSONRPC, AgentInterface::HTTP_JSON].freeze

    # §5.2, §8.3.2 — constructs a Client from an AgentCard by negotiating the
    # protocol binding. The agent's supportedInterfaces order is respected:
    # the first interface whose protocolBinding appears in `preference` wins.
    def self.from_agent_card(card, headers: {}, extensions: [], preference: SUPPORTED_BINDINGS)
      iface = card.preferred_interface(preference: preference)

      unless iface
        found = card.supported_interfaces.map(&:protocol_binding).join(", ")
        raise UnsupportedOperationError, "no supported interface in agent card (available: #{found})"
      end

      Versioning.validate!(iface.protocol_version)

      protocol = build_protocol(iface, headers: headers, extensions: extensions)
      new(protocol: protocol, capabilities: card.capabilities)
    end

    def self.build_protocol(iface, headers:, extensions:)
      klass = iface.protocol_binding == AgentInterface::JSONRPC ? Protocol::JsonRpc : Protocol::HttpJson
      klass.new(url: iface.url, version: iface.protocol_version, headers: headers, extensions: extensions)
    end

    private_class_method :build_protocol

    def initialize(protocol:, capabilities: nil)
      @protocol = protocol
      @capabilities = capabilities
    end

    def send_message(message, configuration: {}, metadata: nil, tenant: nil)
      run Operation::SendMessage.new(message, configuration: configuration, metadata: metadata, tenant: tenant)
    end

    def send_streaming_message(message, configuration: {}, metadata: nil, tenant: nil, &)
      op = Operation::SendStreamingMessage.new(message, configuration: configuration, metadata: metadata,
                                                        tenant: tenant)
      run(op, &)
    end

    def get_task(id, history_length: nil, tenant: nil)
      run Operation::GetTask.new(id:, history_length:, tenant:)
    end

    def list_tasks(**)
      run Operation::ListTasks.new(**)
    end

    def cancel_task(id, metadata: nil, tenant: nil)
      if id.is_a?(Task) && id.terminal?
        raise TaskNotCancelableError, "task #{id.id} is already in a terminal state (#{id.status.state})"
      end

      task_id = id.is_a?(Task) ? id.id : id
      run Operation::CancelTask.new(id: task_id, metadata:, tenant:)
    end

    def subscribe_to_task(id, tenant: nil, &)
      run(Operation::SubscribeToTask.new(id:, tenant:), &)
    end

    def create_task_push_notification_config(config, tenant: nil)
      require_push_notifications!
      run Operation::CreateTaskPushNotificationConfig.new(config, tenant:)
    end

    def get_task_push_notification_config(task_id:, id:, tenant: nil)
      require_push_notifications!
      run Operation::GetTaskPushNotificationConfig.new(task_id:, id:, tenant:)
    end

    def list_task_push_notification_configs(task_id:, page_size: nil, page_token: nil, tenant: nil)
      require_push_notifications!
      run Operation::ListTaskPushNotificationConfigs.new(task_id:, page_size:, page_token:, tenant:)
    end

    def delete_task_push_notification_config(task_id:, id:, tenant: nil)
      require_push_notifications!
      run Operation::DeleteTaskPushNotificationConfig.new(task_id:, id:, tenant:)
    end

    def get_extended_agent_card(tenant: nil)
      require_extended_agent_card!
      run Operation::GetExtendedAgentCard.new(tenant:)
    end

    private

    def require_push_notifications!
      return unless @capabilities&.push_notifications == false

      raise PushNotificationNotSupportedError, "agent does not support push notifications"
    end

    def require_extended_agent_card!
      return unless @capabilities&.extended_agent_card == false

      raise ExtendedAgentCardNotConfiguredError, "agent does not support extended agent card"
    end

    def run(operation, &)
      operation.execute(@protocol, &)
    end
  end
end
