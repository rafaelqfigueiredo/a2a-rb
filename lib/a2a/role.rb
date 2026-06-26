# frozen_string_literal: true

module A2A
  module Role
    UNSPECIFIED = "ROLE_UNSPECIFIED"
    USER        = "ROLE_USER"
    AGENT       = "ROLE_AGENT"

    ALL = [UNSPECIFIED, USER, AGENT].freeze

    def self.valid?(value) = ALL.include?(value)
  end
end
