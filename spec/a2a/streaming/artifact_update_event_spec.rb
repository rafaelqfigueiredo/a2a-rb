# frozen_string_literal: true

RSpec.describe A2A::Streaming::ArtifactUpdateEvent do
  let(:artifact) { A2A::Artifact.new(id: "a1", parts: [A2A::Part::Text.new(text: "result")]) }

  describe "#initialize" do
    it "sets required attributes" do
      event = described_class.new(task_id: "t1", context_id: "ctx1", artifact: artifact)

      expect(event.task_id).to eq "t1"
      expect(event.context_id).to eq "ctx1"
      expect(event.artifact).to eq artifact
    end

    it "defaults append and last_chunk to false and metadata to nil" do
      event = described_class.new(task_id: "t1", context_id: "ctx1", artifact: artifact)

      expect(event.append).to be false
      expect(event.last_chunk).to be false
      expect(event.metadata).to be_nil
    end

    it "accepts all optional attributes" do
      event = described_class.new(
        task_id: "t1",
        context_id: "ctx1",
        artifact: artifact,
        append: true,
        last_chunk: false,
        metadata: { "k" => "v" }
      )

      expect(event.append).to be true
      expect(event.last_chunk).to be false
      expect(event.metadata).to eq({ "k" => "v" })
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      event = described_class.from_h(
        "taskId" => "t1",
        "contextId" => "ctx1",
        "artifact" => { "artifactId" => "a1", "parts" => [{ "text" => "result" }] }
      )

      expect(event.task_id).to eq "t1"
      expect(event.context_id).to eq "ctx1"
      expect(event.artifact).to be_a(A2A::Artifact)
      expect(event.artifact.id).to eq "a1"
    end

    it "deserializes artifact parts" do
      event = described_class.from_h(
        "taskId" => "t1",
        "contextId" => "ctx1",
        "artifact" => { "artifactId" => "a1", "parts" => [{ "text" => "hello" }] }
      )

      expect(event.artifact.parts.first).to be_a(A2A::Part::Text)
      expect(event.artifact.parts.first.text).to eq "hello"
    end

    it "sets append and last_chunk when present" do
      event = described_class.from_h(
        "taskId" => "t1",
        "contextId" => "ctx1",
        "artifact" => { "artifactId" => "a1", "parts" => [{ "text" => "result" }] },
        "append" => true,
        "lastChunk" => true
      )

      expect(event.append).to be true
      expect(event.last_chunk).to be true
    end

    it "raises KeyError when taskId is missing" do
      expect do
        described_class.from_h(
          "contextId" => "ctx1",
          "artifact" => { "artifactId" => "a1", "parts" => [{ "text" => "result" }] }
        )
      end.to raise_error(KeyError)
    end

    it "raises KeyError when contextId is missing" do
      expect do
        described_class.from_h(
          "taskId" => "t1",
          "artifact" => { "artifactId" => "a1", "parts" => [{ "text" => "result" }] }
        )
      end.to raise_error(KeyError)
    end

    it "raises KeyError when artifact is missing" do
      expect { described_class.from_h("taskId" => "t1", "contextId" => "ctx1") }
        .to raise_error(KeyError)
    end
  end
end
