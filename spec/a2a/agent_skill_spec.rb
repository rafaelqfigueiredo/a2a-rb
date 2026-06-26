# frozen_string_literal: true

RSpec.describe A2A::AgentSkill do
  describe "#initialize" do
    it "sets required attributes" do
      skill = described_class.new(
        id: "search",
        name: "Web Search",
        description: "Searches the web",
        tags: ["search", "web"]
      )

      expect(skill.id).to eq "search"
      expect(skill.name).to eq "Web Search"
      expect(skill.description).to eq "Searches the web"
      expect(skill.tags).to eq ["search", "web"]
    end

    it "raises ArgumentError when tags is empty" do
      expect { described_class.new(id: "search", name: "Web Search", description: "Searches the web", tags: []) }
        .to raise_error(ArgumentError, /tags must contain at least one element/)
    end

    it "defaults optional attributes to nil" do
      skill = described_class.new(
        id: "search", name: "Web Search", description: "Searches the web", tags: ["search"]
      )

      expect(skill.examples).to be_nil
      expect(skill.input_modes).to be_nil
      expect(skill.output_modes).to be_nil
      expect(skill.security_requirements).to be_nil
    end

    it "accepts optional attributes" do
      req = A2A::SecurityRequirement.new(schemes: { "bearer" => [] })
      skill = described_class.new(
        id: "search",
        name: "Web Search",
        description: "Searches the web",
        tags: ["search"],
        examples: ["Find the weather"],
        input_modes: ["text/plain"],
        output_modes: ["text/plain"],
        security_requirements: [req]
      )

      expect(skill.examples).to eq ["Find the weather"]
      expect(skill.input_modes).to eq ["text/plain"]
      expect(skill.output_modes).to eq ["text/plain"]
      expect(skill.security_requirements).to eq [req]
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      skill = described_class.from_h(
        "id" => "search",
        "name" => "Web Search",
        "description" => "Searches the web",
        "tags" => ["search"]
      )

      expect(skill.id).to eq "search"
      expect(skill.name).to eq "Web Search"
      expect(skill.description).to eq "Searches the web"
      expect(skill.tags).to eq ["search"]
      expect(skill.examples).to be_nil
      expect(skill.input_modes).to be_nil
      expect(skill.output_modes).to be_nil
      expect(skill.security_requirements).to be_nil
    end

    it "builds from a full hash" do
      skill = described_class.from_h(
        "id" => "search",
        "name" => "Web Search",
        "description" => "Searches the web",
        "tags" => ["search"],
        "examples" => ["Find the weather"],
        "inputModes" => ["text/plain"],
        "outputModes" => ["text/plain"],
        "securityRequirements" => [{ "bearer" => [] }]
      )

      expect(skill.examples).to eq ["Find the weather"]
      expect(skill.input_modes).to eq ["text/plain"]
      expect(skill.output_modes).to eq ["text/plain"]
      expect(skill.security_requirements.first).to be_a(A2A::SecurityRequirement)
      expect(skill.security_requirements.first.schemes).to eq({ "bearer" => [] })
    end

    it "raises KeyError when id is missing" do
      expect do
        described_class.from_h("name" => "Web Search", "description" => "Searches the web", "tags" => ["search"])
      end.to raise_error(KeyError)
    end

    it "raises KeyError when name is missing" do
      expect do
        described_class.from_h("id" => "search", "description" => "Searches the web", "tags" => ["search"])
      end.to raise_error(KeyError)
    end

    it "raises KeyError when description is missing" do
      expect do
        described_class.from_h("id" => "search", "name" => "Web Search", "tags" => ["search"])
      end.to raise_error(KeyError)
    end

    it "raises KeyError when tags is missing" do
      expect do
        described_class.from_h("id" => "search", "name" => "Web Search", "description" => "Searches the web")
      end.to raise_error(KeyError)
    end

    it "raises ArgumentError when tags is empty" do
      expect do
        described_class.from_h("id" => "search", "name" => "Web Search", "description" => "Searches the web", "tags" => [])
      end.to raise_error(ArgumentError, /tags must contain at least one element/)
    end
  end

  describe ".from_h unknown keys" do
    it "ignores unrecognized fields" do
      skill = described_class.from_h(
        "id" => "s1", "name" => "S", "description" => "d", "tags" => ["t"],
        "newField" => "ignored"
      )
      expect(skill.id).to eq "s1"
    end
  end

  describe "#to_h" do
    it "serializes all fields" do
      skill = described_class.new(
        id: "search",
        name: "Web Search",
        description: "Searches the web",
        tags: ["search"],
        examples: ["Find the weather"],
        input_modes: ["text/plain"],
        output_modes: ["text/plain"]
      )

      result = skill.to_h
      expect(result["id"]).to eq "search"
      expect(result["name"]).to eq "Web Search"
      expect(result["description"]).to eq "Searches the web"
      expect(result["tags"]).to eq ["search"]
      expect(result["examples"]).to eq ["Find the weather"]
      expect(result["inputModes"]).to eq ["text/plain"]
      expect(result["outputModes"]).to eq ["text/plain"]
      expect(result).not_to have_key("securityRequirements")
    end

    it "omits nil optional fields" do
      skill = described_class.new(
        id: "search", name: "Web Search", description: "Searches the web", tags: ["search"]
      )

      result = skill.to_h
      expect(result).not_to have_key("examples")
      expect(result).not_to have_key("inputModes")
      expect(result).not_to have_key("outputModes")
      expect(result).not_to have_key("securityRequirements")
    end

    it "serializes security requirements" do
      req = A2A::SecurityRequirement.new(schemes: { "bearer" => ["read"] })
      skill = described_class.new(
        id: "search", name: "Web Search", description: "Searches the web",
        tags: ["search"], security_requirements: [req]
      )

      expect(skill.to_h["securityRequirements"]).to eq [{ "bearer" => ["read"] }]
    end

    it "round-trips through from_h" do
      skill = described_class.new(
        id: "search", name: "Web Search", description: "Searches the web",
        tags: ["search"], examples: ["query"], input_modes: ["text/plain"], output_modes: ["text/plain"]
      )
      restored = described_class.from_h(skill.to_h)

      expect(restored.id).to eq skill.id
      expect(restored.name).to eq skill.name
      expect(restored.tags).to eq skill.tags
    end
  end
end
