# frozen_string_literal: true

module A2A
  class Part
    class Data
      attr_reader :data, :media_type, :filename, :metadata

      def initialize(data:, media_type: nil, filename: nil, metadata: nil)
        @data = data
        @media_type = media_type
        @filename = filename
        @metadata = metadata
      end

      def self.from_h(hash)
        new(
          data: hash.fetch("data"),
          media_type: hash["mediaType"],
          filename: hash["filename"],
          metadata: hash["metadata"]
        )
      end

      def to_h
        {
          "data" => data,
          "mediaType" => media_type,
          "filename" => filename,
          "metadata" => metadata
        }.compact
      end
    end
  end
end
