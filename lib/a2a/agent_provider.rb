# frozen_string_literal: true

module A2A
  class AgentProvider
    attr_reader :organization, :url

    def initialize(organization:, url:)
      @organization = organization
      @url = url
    end

    def self.from_h(hash)
      new(organization: hash.fetch("organization"), url: hash.fetch("url"))
    end

    def to_h
      { "organization" => organization, "url" => url }
    end
  end
end
