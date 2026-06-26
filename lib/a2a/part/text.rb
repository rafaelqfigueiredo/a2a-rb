# frozen_string_literal: true

module A2A
  class Part
    class Text
      attr_reader :text, :media_type, :filename, :metadata

      def initialize(text:, media_type: nil, filename: nil, metadata: nil)
        @text = text
        @media_type = media_type
        @filename = filename
        @metadata = metadata
      end

      def self.from_h(hash)
        new(
          text: hash.fetch("text"),
          media_type: hash["mediaType"],
          filename: hash["filename"],
          metadata: hash["metadata"]
        )
      end

      def to_h
        {
          "text" => text,
          "mediaType" => media_type,
          "filename" => filename,
          "metadata" => metadata
        }.compact
      end
    end
  end
end
