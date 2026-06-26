# frozen_string_literal: true

module A2A
  class AgentCard
    # Fluent builder for constructing an AgentCard without deep nested constructors.
    #
    # Usage:
    #   card = A2A::AgentCard::Builder.new
    #     .name("My Agent")
    #     .description("Does things")
    #     .version("1.0")
    #     .interface(url: "https://agent.example.com/rpc", protocol_binding: A2A::AgentInterface::JSONRPC)
    #     .capabilities(streaming: true)
    #     .input_modes("text/plain")
    #     .output_modes("text/plain")
    #     .skill(id: "summarise", name: "Summarise", description: "Summarises text", tags: ["text"])
    #     .build
    class Builder
      def initialize
        @name = nil
        @description = nil
        @version = nil
        @interfaces = []
        @capabilities_opts = {}
        @input_modes = []
        @output_modes = []
        @skills = []
        @provider = nil
        @documentation_url = nil
        @icon_url = nil
        @security_schemes = {}
        @security_requirements = nil
      end

      def name(value)
        @name = value
        self
      end

      def description(value)
        @description = value
        self
      end

      def version(value)
        @version = value
        self
      end

      # Appends a supported interface. Accepts either an AgentInterface object
      # or kwargs forwarded to AgentInterface.new.
      def interface(iface = nil, **kwargs)
        @interfaces << (iface.is_a?(AgentInterface) ? iface : AgentInterface.new(**kwargs))
        self
      end

      # Sets capabilities via kwargs (streaming:, push_notifications:, etc.)
      # or accepts an AgentCapabilities object directly.
      def capabilities(caps = nil, **kwargs)
        @capabilities_opts = caps.is_a?(AgentCapabilities) ? caps : kwargs
        self
      end

      # Appends one or more accepted input MIME types.
      def input_modes(*modes)
        @input_modes.concat(modes.flatten)
        self
      end

      # Appends one or more accepted output MIME types.
      def output_modes(*modes)
        @output_modes.concat(modes.flatten)
        self
      end

      # Appends a skill. Accepts either an AgentSkill object or kwargs
      # forwarded to AgentSkill.new.
      def skill(obj = nil, **kwargs)
        @skills << (obj.is_a?(AgentSkill) ? obj : AgentSkill.new(**kwargs))
        self
      end

      def provider(org, url: nil)
        @provider = AgentProvider.new(organization: org, url: url)
        self
      end

      def documentation_url(value)
        @documentation_url = value
        self
      end

      def icon_url(value)
        @icon_url = value
        self
      end

      # Registers a security scheme under `name`. Accepts a SecurityScheme
      # subclass or a raw hash forwarded to SecurityScheme.from_h.
      def security_scheme(name, scheme)
        @security_schemes[name] = scheme.is_a?(Hash) ? SecurityScheme.from_h(scheme) : scheme
        self
      end

      def security(requirements)
        @security_requirements = requirements
        self
      end

      def build
        AgentCard.new(
          name: @name,
          description: @description,
          version: @version,
          supported_interfaces: @interfaces,
          capabilities: resolve_capabilities,
          default_input_modes: @input_modes,
          default_output_modes: @output_modes,
          skills: @skills,
          provider: @provider,
          documentation_url: @documentation_url,
          icon_url: @icon_url,
          security_schemes: @security_schemes.empty? ? nil : @security_schemes,
          security_requirements: @security_requirements
        )
      end

      private

      def resolve_capabilities
        @capabilities_opts.is_a?(AgentCapabilities) ? @capabilities_opts : AgentCapabilities.new(**@capabilities_opts)
      end
    end
  end
end
