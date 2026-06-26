# frozen_string_literal: true

module A2A
  class Part
    class File
      attr_reader :raw, :url, :filename, :media_type, :metadata

      def initialize(raw: nil, url: nil, filename: nil, media_type: nil, metadata: nil)
        @raw = raw
        @url = url
        @filename = filename
        @media_type = media_type
        @metadata = metadata
      end

      def self.from_h(hash)
        new(
          raw: hash["raw"],
          url: hash["url"],
          filename: hash["filename"],
          media_type: hash["mediaType"],
          metadata: hash["metadata"]
        )
      end

      def to_h
        {
          "raw" => raw,
          "url" => url,
          "filename" => filename,
          "mediaType" => media_type,
          "metadata" => metadata
        }.compact
      end

      def inline?
        !raw.nil?
      end

      def remote?
        !url.nil?
      end
    end
  end
end
