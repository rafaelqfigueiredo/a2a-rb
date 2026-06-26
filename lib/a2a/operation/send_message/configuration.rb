# frozen_string_literal: true

module A2A
  module Operation
    class SendMessage
      class Configuration
        attr_reader :accepted_output_modes, :task_push_notification_config, :history_length,
                    :return_immediately

        def initialize(**kwargs)
          @accepted_output_modes = kwargs[:accepted_output_modes]
          @task_push_notification_config = kwargs[:task_push_notification_config]
          @history_length = kwargs[:history_length]
          @return_immediately = kwargs[:return_immediately]
        end

        def self.from_h(hash)
          new(
            accepted_output_modes: hash["acceptedOutputModes"],
            task_push_notification_config: hash["taskPushNotificationConfig"],
            history_length: hash["historyLength"],
            return_immediately: hash["returnImmediately"]
          )
        end

        def to_h
          push_config = task_push_notification_config
          push_config = push_config.to_h if push_config.is_a?(PushNotification::Config)
          {
            "acceptedOutputModes" => accepted_output_modes,
            "taskPushNotificationConfig" => push_config,
            "historyLength" => history_length,
            "returnImmediately" => return_immediately
          }.compact
        end
      end
    end
  end
end
