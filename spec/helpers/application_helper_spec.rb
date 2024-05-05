require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "number_display" do
    let(:target) { "<span>1</span>" }
    it "renders" do
      expect(number_display(1)).to eq target
    end
    context "with round_to" do
      let(:target) { "<span>1.0</span>" }
      it "renders" do
        expect(number_display(1, round_to: 1)).to eq target
      end
    end
  end
end
