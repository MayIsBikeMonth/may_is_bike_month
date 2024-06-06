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

  describe 'competition_activity_display' do
    let(:competition_activity) { FactoryBot.create(:competition_activity) }
    let(:target) { '<span>Cool ride</span>' }
    it 'renders' do
      expect(competition_activity_display(competition_activity)).to eq target
    end
    context 'with manual_entry entered_after_competition_ended' do
      before do
        allow(competition_activity).to receive(:manual_entry?).and_return(true)
        allow(competition_activity).to receive(:entered_after_competition_ended?).and_return(true)
      end
      let(:target) { '<span>Cool ride <em class="less-strong">ignored, manual entry after competition ended</em></span>' }
      it 'renders' do
        expect(competition_activity_display(competition_activity)).to eq target
      end
    end
  end
end
