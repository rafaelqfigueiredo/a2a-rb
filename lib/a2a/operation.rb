# frozen_string_literal: true

require_relative "operation/executable"
require_relative "operation/send_message"
require_relative "operation/send_streaming_message"
require_relative "operation/get_task"
require_relative "operation/list_tasks"
require_relative "operation/cancel_task"
require_relative "operation/subscribe_to_task"
require_relative "operation/create_task_push_notification_config"
require_relative "operation/get_task_push_notification_config"
require_relative "operation/list_task_push_notification_configs"
require_relative "operation/delete_task_push_notification_config"
require_relative "operation/get_extended_agent_card"

module A2A
  module Operation
  end
end
