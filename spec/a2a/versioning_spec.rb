# frozen_string_literal: true

RSpec.describe A2A::Versioning do
  describe ".normalize" do
    it "returns Major.Minor unchanged" do
      expect(described_class.normalize("1.0")).to eq "1.0"
    end

    it "strips patch segment" do
      expect(described_class.normalize("1.0.2")).to eq "1.0"
    end
  end

  describe ".supported?" do
    it "returns true for the current spec version" do
      expect(described_class.supported?("1.0")).to be true
    end

    it "returns false for an unsupported version" do
      expect(described_class.supported?("0.3")).to be false
    end

    it "returns false for an unknown version" do
      expect(described_class.supported?("2.0")).to be false
    end

    it "returns false for an empty string" do
      expect(described_class.supported?("")).to be false
    end
  end

  describe ".validate!" do
    it "returns the normalized version for a supported version" do
      expect(described_class.validate!("1.0")).to eq "1.0"
    end

    it "normalizes and accepts a version with a patch segment" do
      expect(described_class.validate!("1.0.9")).to eq "1.0"
    end

    it "raises VersionNotSupportedError for an unsupported version" do
      expect { described_class.validate!("2.0") }
        .to raise_error(A2A::VersionNotSupportedError, /unsupported A2A version: 2\.0/)
    end

    it "raises VersionNotSupportedError for 0.3" do
      expect { described_class.validate!("0.3") }
        .to raise_error(A2A::VersionNotSupportedError)
    end

    it "raises VersionNotSupportedError for an empty string" do
      expect { described_class.validate!("") }
        .to raise_error(A2A::VersionNotSupportedError)
    end
  end

  describe "constants" do
    it "sets CURRENT to the gem SPEC_VERSION" do
      expect(described_class::CURRENT).to eq A2A::SPEC_VERSION
    end

    it "SUPPORTED contains only CURRENT" do
      expect(described_class::SUPPORTED).to eq [A2A::SPEC_VERSION]
    end
  end
end
