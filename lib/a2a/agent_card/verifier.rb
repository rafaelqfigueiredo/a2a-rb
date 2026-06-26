# frozen_string_literal: true

module A2A
  class AgentCard
    # §8.4.3 — Verifies AgentCard signatures.
    # Signing is optional; unsigned cards are considered valid.
    # Full JWS verification (RFC 7515 + RFC 8785 canonicalisation) is not yet
    # implemented. See §8.4 of the A2A spec for the required algorithm.
    class Verifier
      def self.verify!(card)
        return true if card.signatures.nil? || card.signatures.empty?

        raise NotImplementedError,
              "AgentCard signature verification is not yet implemented (§8.4). " \
              "The card carries #{card.signatures.length} signature(s) but they cannot be verified."
      end
    end
  end
end
