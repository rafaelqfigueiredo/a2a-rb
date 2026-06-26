# frozen_string_literal: true

RSpec.describe A2A::Task::State do
  it "uses TASK_STATE_* canonical strings" do
    expect(described_class::UNSPECIFIED).to eq("TASK_STATE_UNSPECIFIED")
    expect(described_class::SUBMITTED).to eq("TASK_STATE_SUBMITTED")
  end

  it "identifies valid states" do
    expect(described_class.valid?("TASK_STATE_UNSPECIFIED")).to be true
    expect(described_class.valid?("TASK_STATE_WORKING")).to be true
    expect(described_class.valid?("INVALID")).to be false
  end

  it "identifies terminal states" do
    expect(described_class.terminal?("TASK_STATE_COMPLETED")).to be true
    expect(described_class.terminal?("TASK_STATE_WORKING")).to be false
    expect(described_class.terminal?("TASK_STATE_UNSPECIFIED")).to be false
  end

  describe "RESUMABLE" do
    it "contains INPUT_REQUIRED and AUTH_REQUIRED" do
      expect(described_class::RESUMABLE).to contain_exactly(
        described_class::INPUT_REQUIRED,
        described_class::AUTH_REQUIRED
      )
    end

    it "does not overlap with TERMINAL" do
      expect(described_class::RESUMABLE & described_class::TERMINAL).to be_empty
    end
  end
end
