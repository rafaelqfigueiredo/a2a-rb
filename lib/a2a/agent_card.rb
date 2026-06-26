# frozen_string_literal: true

require "json"
require_relative "agent_card/signature"
require_relative "agent_card/verifier"
require_relative "agent_card/builder"

module A2A
  class AgentCard
    attr_reader :name, :description, :supported_interfaces, :provider, :version,
                :documentation_url, :capabilities, :security_schemes, :security_requirements,
                :default_input_modes, :default_output_modes, :skills, :signatures, :icon_url

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def initialize(name:, description:, **kwargs)
      supported_interfaces = kwargs.fetch(:supported_interfaces)
      default_input_modes = kwargs.fetch(:default_input_modes)
      default_output_modes = kwargs.fetch(:default_output_modes)
      skills = kwargs.fetch(:skills)

      validate_required_collections!(supported_interfaces, default_input_modes, default_output_modes, skills)

      @name = name
      @description = description
      @supported_interfaces = supported_interfaces
      @version = kwargs.fetch(:version)
      @capabilities = kwargs.fetch(:capabilities)
      @default_input_modes = default_input_modes
      @default_output_modes = default_output_modes
      @skills = skills
      @provider = kwargs.fetch(:provider, nil)
      @documentation_url = kwargs.fetch(:documentation_url, nil)
      @security_schemes = kwargs.fetch(:security_schemes, nil)
      @security_requirements = kwargs.fetch(:security_requirements, nil)
      @signatures = kwargs.fetch(:signatures, nil)
      @icon_url = kwargs.fetch(:icon_url, nil)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.from_h(hash)
      new(
        name: hash.fetch("name"),
        description: hash.fetch("description"),
        version: hash.fetch("version"),
        supported_interfaces: hash.fetch("supportedInterfaces").map { AgentInterface.from_h(it) },
        capabilities: AgentCapabilities.from_h(hash.fetch("capabilities")),
        skills: hash.fetch("skills").map { AgentSkill.from_h(it) },
        security_schemes: (hash["securitySchemes"] || {}).transform_values { SecurityScheme.from_h(it) },
        security_requirements: hash["security"],
        default_input_modes: hash.fetch("defaultInputModes"),
        default_output_modes: hash.fetch("defaultOutputModes"),
        provider: hash["provider"] && AgentProvider.from_h(hash["provider"]),
        documentation_url: hash["documentationUrl"],
        icon_url: hash["iconUrl"],
        signatures: hash["signatures"]&.map { Signature.from_h(it) }
      )
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def to_h
      required_fields.merge(optional_fields).compact
    end

    # §8.4.1 — RFC 8785 canonical JSON: to_h with "signatures" excluded and
    # keys sorted recursively. Used as the payload for JWS signing/verification.
    def canonical_json
      JSON.generate(sort_keys_recursive(to_h.except("signatures")))
    end

    # §5.2 — returns the first interface whose protocolBinding the caller supports,
    # preserving the agent's declared preference order (index 0 = most preferred).
    def preferred_interface(preference: [AgentInterface::JSONRPC, AgentInterface::HTTP_JSON])
      supported_interfaces.find { |i| preference.include?(i.protocol_binding) }
    end

    private

    def validate_required_collections!(interfaces, input_modes, output_modes, skills)
      raise ArgumentError, "supported_interfaces must contain at least one element" if Array(interfaces).empty?
      raise ArgumentError, "skills must contain at least one element" if Array(skills).empty?
      raise ArgumentError, "default_input_modes must contain at least one element" if Array(input_modes).empty?
      raise ArgumentError, "default_output_modes must contain at least one element" if Array(output_modes).empty?
    end

    def required_fields
      {
        "name" => name,
        "description" => description,
        "version" => version,
        "supportedInterfaces" => supported_interfaces.map(&:to_h),
        "capabilities" => capabilities.to_h,
        "skills" => skills.map(&:to_h),
        "defaultInputModes" => default_input_modes,
        "defaultOutputModes" => default_output_modes
      }
    end

    def optional_fields
      {
        "provider" => provider&.to_h,
        "documentationUrl" => documentation_url,
        "iconUrl" => icon_url,
        "securitySchemes" => security_schemes&.transform_values(&:to_h),
        "security" => security_requirements,
        "signatures" => signatures&.map(&:to_h)
      }
    end

    def sort_keys_recursive(obj)
      case obj
      when Hash then obj.sort.to_h.transform_values { sort_keys_recursive(it) }
      when Array then obj.map { sort_keys_recursive(it) }
      else obj
      end
    end
  end
end
