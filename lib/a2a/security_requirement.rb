# frozen_string_literal: true

module A2A
  class SecurityRequirement
    attr_reader :schemes

    def initialize(schemes:)
      @schemes = schemes
    end

    def self.from_h(hash)
      new(schemes: hash.transform_values { _1.is_a?(Array) ? _1 : _1["list"] })
    end

    def to_h
      schemes
    end
  end
end
