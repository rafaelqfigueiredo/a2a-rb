# frozen_string_literal: true

module A2A
  class AgentExtension
    attr_reader :uri, :description, :required, :params

    def initialize(uri: nil, description: nil, required: nil, params: nil)
      @uri = uri
      @description = description
      @required = required
      @params = params
    end

    def self.from_h(hash)
      new(
        uri: hash["uri"],
        description: hash["description"],
        required: hash["required"],
        params: hash["params"]
      )
    end

    def to_h
      {
        "uri" => uri,
        "description" => description,
        "required" => required,
        "params" => params
      }.compact
    end
  end
end
