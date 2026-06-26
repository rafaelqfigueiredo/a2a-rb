# frozen_string_literal: true

RSpec.describe A2A::PushNotification::AuthenticationInfo do
  describe "#initialize" do
    it "sets required scheme" do
      info = described_class.new(scheme: "Bearer")

      expect(info.scheme).to eq "Bearer"
    end

    it "defaults credentials to nil" do
      info = described_class.new(scheme: "Bearer")

      expect(info.credentials).to be_nil
    end

    it "accepts credentials" do
      info = described_class.new(scheme: "Bearer", credentials: "tok_abc123")

      expect(info.credentials).to eq "tok_abc123"
    end
  end

  describe ".from_h" do
    it "builds from a minimal hash" do
      info = described_class.from_h("scheme" => "Bearer")

      expect(info.scheme).to eq "Bearer"
      expect(info.credentials).to be_nil
    end

    it "raises KeyError when scheme is missing" do
      expect { described_class.from_h({}) }.to raise_error(KeyError)
    end

    it "deserializes credentials when present" do
      info = described_class.from_h("scheme" => "Bearer", "credentials" => "tok_abc123")

      expect(info.credentials).to eq "tok_abc123"
    end
  end

  describe "#authorization_header" do
    it "returns scheme and credentials joined by a space" do
      info = described_class.new(scheme: "Bearer", credentials: "tok_abc")

      expect(info.authorization_header).to eq("Bearer tok_abc")
    end

    it "returns only the scheme when credentials are nil" do
      info = described_class.new(scheme: "Bearer")

      expect(info.authorization_header).to eq("Bearer")
    end
  end

  describe "#to_h" do
    it "serializes scheme and credentials" do
      info = described_class.new(scheme: "Bearer", credentials: "tok_abc123")

      expect(info.to_h).to eq({ "scheme" => "Bearer", "credentials" => "tok_abc123" })
    end

    it "omits nil credentials" do
      info = described_class.new(scheme: "Bearer")

      expect(info.to_h).to eq({ "scheme" => "Bearer" })
    end
  end
end
