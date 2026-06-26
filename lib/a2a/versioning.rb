# frozen_string_literal: true

module A2A
  module Versioning
    CURRENT = SPEC_VERSION
    SUPPORTED = [CURRENT].freeze

    # Returns the normalized Major.Minor string from a version value.
    # Strips any patch segment so "1.0.2" is treated as "1.0".
    def self.normalize(version)
      parts = version.to_s.split(".")
      "#{parts[0]}.#{parts[1]}"
    end

    def self.supported?(version)
      SUPPORTED.include?(version.to_s)
    end

    # Raises VersionNotSupportedError when the version is not in SUPPORTED.
    # Returns the normalized version string when valid.
    def self.validate!(version)
      v = normalize(version)
      raise VersionNotSupportedError, "unsupported A2A version: #{v}" unless supported?(v)

      v
    end
  end
end
