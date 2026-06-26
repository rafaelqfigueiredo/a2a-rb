# frozen_string_literal: true

module A2A
  class AgentCard
    # §8.4.2 — JWS signature attached to an AgentCard.
    # `protected` is the base64url-encoded JWS Protected Header.
    # `signature` is the base64url-encoded signature value.
    # `header` is the optional JWS Unprotected Header (plain JSON object, not encoded).
    class Signature
      attr_reader :protected_header, :signature, :header

      def initialize(protected_header:, signature:, header: nil)
        @protected_header = protected_header
        @signature = signature
        @header = header
      end

      def self.from_h(hash)
        new(
          protected_header: hash.fetch("protected"),
          signature: hash.fetch("signature"),
          header: hash["header"]
        )
      end

      def to_h
        {
          "protected" => protected_header,
          "signature" => signature,
          "header" => header
        }.compact
      end
    end
  end
end
