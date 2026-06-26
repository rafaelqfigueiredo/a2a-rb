# frozen_string_literal: true

require_relative "part/text"
require_relative "part/data"
require_relative "part/file"

module A2A
  class Part
    def self.from_h(hash)
      if hash.key?("text")
        Part::Text.from_h(hash)
      elsif hash.key?("data")
        Part::Data.from_h(hash)
      elsif hash.key?("raw") || hash.key?("url")
        Part::File.from_h(hash)
      else
        raise ArgumentError, "cannot detect Part type from keys: #{hash.keys.inspect}"
      end
    end
  end
end
