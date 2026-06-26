# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module A2A
  module Discovery
    WELL_KNOWN_PATH = "/.well-known/agent-card.json"

    # §8.2, §14.3 — fetches the public AgentCard from /.well-known/a2a.
    # No authentication required.
    def self.fetch(base_url, transport: Transport.new)
      url = "#{base_url.chomp('/')}#{WELL_KNOWN_PATH}"
      AgentCard.from_h(transport.get(url))
    end

    # §8.6.2 — fetches the public card, then calls GetExtendedAgentCard.
    # The public card must declare capabilities.extendedAgentCard: true.
    def self.fetch_extended(base_url, headers: {}, extensions: [], transport: Transport.new)
      card = fetch(base_url, transport: transport)
      Client.from_agent_card(card, headers: headers, extensions: extensions)
            .get_extended_agent_card
    end

    class Transport
      def get(url)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        response = http.request(Net::HTTP::Get.new(uri.request_uri,
                                                   "Accept" => "application/json"))
        handle(response)
      end

      private

      def handle(response)
        case response.code.to_i
        when 200..299 then JSON.parse(response.body)
        when 401 then raise AuthenticationError, "HTTP 401"
        when 403 then raise AuthorizationError, "HTTP 403"
        when 404 then raise TransportError, "agent card not found (HTTP 404)"
        else raise TransportError, "HTTP #{response.code}"
        end
      end
    end
  end
end
