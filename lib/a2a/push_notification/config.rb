# frozen_string_literal: true

module A2A
  module PushNotification
    class Config
      attr_reader :id, :url, :token, :tenant, :task_id, :authentication

      def initialize(url:, **kwargs)
        @url = url
        @id = kwargs[:id]
        @token = kwargs[:token]
        @tenant = kwargs[:tenant]
        @task_id = kwargs[:task_id]
        @authentication = kwargs[:authentication]
      end

      def self.from_h(hash)
        new(
          url: hash.fetch("url"),
          id: hash["id"],
          token: hash["token"],
          tenant: hash["tenant"],
          task_id: hash["taskId"],
          authentication: hash["authentication"] && AuthenticationInfo.from_h(hash["authentication"])
        )
      end

      def to_h
        {
          "url" => url,
          "id" => id,
          "token" => token,
          "tenant" => tenant,
          "taskId" => task_id,
          "authentication" => authentication
        }.compact
      end
    end
  end
end
