# frozen_string_literal: true

RSpec.describe A2A::Role do
  it "uses ROLE_* canonical strings" do
    expect(described_class::USER).to eq "ROLE_USER"
    expect(described_class::AGENT).to eq "ROLE_AGENT"
  end

  it "validates membership" do
    expect(described_class.valid?("ROLE_USER")).to be true
    expect(described_class.valid?("INVALID")).to be false
  end
end
