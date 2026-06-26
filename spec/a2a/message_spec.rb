# frozen_string_literal: true

RSpec.describe A2A::Message do
  let(:text_part) { A2A::Part::Text.new(text: "hello") }

  describe "#initialize" do
    it "raises ArgumentError for an invalid role" do
      expect { described_class.new(id: "m1", role: "ROLE_INVALID", parts: []) }
        .to raise_error(ArgumentError, /invalid role/)
    end

    it "sets required attributes" do
      msg = described_class.new(id: "m1", role: A2A::Role::USER, parts: [text_part])

      expect(msg.id).to eq "m1"
      expect(msg.role).to eq A2A::Role::USER
      expect(msg.parts).to eq [text_part]
    end

    it "raises ArgumentError when parts is empty" do
      expect { described_class.new(id: "m1", role: A2A::Role::USER, parts: []) }
        .to raise_error(ArgumentError, /parts must contain at least one element/)
    end

    it "defaults optional attributes" do
      msg = described_class.new(id: "m1", role: A2A::Role::USER, parts: [A2A::Part::Text.new(text: "hi")])

      expect(msg.context_id).to be_nil
      expect(msg.task_id).to be_nil
      expect(msg.reference_task_ids).to be_nil
      expect(msg.extensions).to be_nil
      expect(msg.metadata).to be_nil
    end

    it "accepts all optional attributes" do
      msg = described_class.new(
        id: "m1",
        role: A2A::Role::AGENT,
        parts: [A2A::Part::Text.new(text: "hi")],
        context_id: "ctx1",
        task_id: "t1",
        reference_task_ids: ["t0"],
        extensions: ["https://example.com/ext"],
        metadata: { "key" => "value" }
      )

      expect(msg.context_id).to eq "ctx1"
      expect(msg.task_id).to eq "t1"
      expect(msg.reference_task_ids).to eq ["t0"]
      expect(msg.extensions).to eq ["https://example.com/ext"]
      expect(msg.metadata).to eq({ "key" => "value" })
    end
  end

  describe ".from_h" do
    it "builds from a minimal JSON hash" do
      msg = described_class.from_h(
        "messageId" => "m1",
        "role" => A2A::Role::USER,
        "parts" => [{ "text" => "hi" }]
      )

      expect(msg.id).to eq "m1"
      expect(msg.role).to eq A2A::Role::USER
      expect(msg.parts.first).to be_a(A2A::Part::Text)
      expect(msg.parts.first.text).to eq "hi"
    end

    it "builds from a full JSON hash" do
      msg = described_class.from_h(
        "messageId" => "m2",
        "role" => A2A::Role::AGENT,
        "parts" => [{ "text" => "hi" }],
        "contextId" => "ctx1",
        "taskId" => "t1",
        "referenceTaskIds" => ["t0"],
        "extensions" => ["https://example.com/ext"],
        "metadata" => { "k" => "v" }
      )

      expect(msg.context_id).to eq "ctx1"
      expect(msg.task_id).to eq "t1"
      expect(msg.reference_task_ids).to eq ["t0"]
      expect(msg.extensions).to eq ["https://example.com/ext"]
      expect(msg.metadata).to eq({ "k" => "v" })
    end

    it "defaults reference_task_ids and extensions to nil when absent" do
      msg = described_class.from_h("messageId" => "m1", "role" => A2A::Role::USER, "parts" => [{ "text" => "hi" }])

      expect(msg.reference_task_ids).to be_nil
      expect(msg.extensions).to be_nil
    end

    it "raises KeyError when messageId is missing" do
      expect { described_class.from_h("role" => A2A::Role::USER, "parts" => []) }
        .to raise_error(KeyError)
    end

    it "raises KeyError when role is missing" do
      expect { described_class.from_h("messageId" => "m1", "parts" => []) }
        .to raise_error(KeyError)
    end
  end

  describe "#to_h" do
    it "serializes required fields" do
      msg = described_class.new(id: "m1", role: A2A::Role::USER, parts: [text_part])

      result = msg.to_h
      expect(result["messageId"]).to eq "m1"
      expect(result["role"]).to eq A2A::Role::USER
      expect(result["parts"].first["text"]).to eq "hello"
    end

    it "omits nil optional fields" do
      msg = described_class.new(id: "m1", role: A2A::Role::USER, parts: [text_part])

      result = msg.to_h
      expect(result).not_to have_key("contextId")
      expect(result).not_to have_key("taskId")
      expect(result).not_to have_key("metadata")
      expect(result).not_to have_key("referenceTaskIds")
      expect(result).not_to have_key("extensions")
    end

    it "includes optional fields when present" do
      msg = described_class.new(
        id: "m1",
        role: A2A::Role::USER,
        parts: [text_part],
        context_id: "ctx1",
        task_id: "t1",
        reference_task_ids: ["t0"],
        extensions: ["https://example.com/ext"],
        metadata: { "k" => "v" }
      )

      result = msg.to_h
      expect(result["contextId"]).to eq "ctx1"
      expect(result["taskId"]).to eq "t1"
      expect(result["referenceTaskIds"]).to eq ["t0"]
      expect(result["extensions"]).to eq ["https://example.com/ext"]
      expect(result["metadata"]).to eq({ "k" => "v" })
    end
  end

  describe ".from_h unknown keys" do
    it "ignores unrecognized fields" do
      msg = described_class.from_h(
        "messageId" => "m1",
        "role" => A2A::Role::USER,
        "parts" => [{ "text" => "hi" }],
        "unknownField" => "ignored",
        "futureExtension" => { "data" => 42 }
      )
      expect(msg.id).to eq "m1"
    end
  end

  describe "#to_h round-trip" do
    it "round-trips through from_h" do
      original = described_class.new(
        id: "m1", role: A2A::Role::USER, parts: [text_part],
        context_id: "ctx1", task_id: "t1"
      )
      restored = described_class.from_h(original.to_h)

      expect(restored.id).to eq original.id
      expect(restored.role).to eq original.role
      expect(restored.context_id).to eq original.context_id
      expect(restored.task_id).to eq original.task_id
      expect(restored.parts.first.text).to eq "hello"
    end
  end

  describe "#text" do
    it "returns the text of the first Text part" do
      msg = described_class.new(id: "m1", role: A2A::Role::USER, parts: [text_part])

      expect(msg.text).to eq "hello"
    end

    it "returns nil when there are no Text parts" do
      file_part = A2A::Part::File.new(url: "https://example.com/f")
      msg = described_class.new(id: "m1", role: A2A::Role::USER, parts: [file_part])

      expect(msg.text).to be_nil
    end

    it "returns nil when there are no Text parts among parts" do
      file_part2 = A2A::Part::File.new(url: "https://example.com/f2")
      msg = described_class.new(id: "m1", role: A2A::Role::USER, parts: [file_part2])

      expect(msg.text).to be_nil
    end
  end
end
