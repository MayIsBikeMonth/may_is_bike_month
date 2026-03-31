# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationComponentHelper, type: :helper do
  describe "number_display" do
    subject(:result) { helper.number_display(number) }

    context "with large number" do
      let(:number) { 1234 }

      it "formats numbers with delimiter" do
        expect(result).to eq '<span>1,234</span>'
      end
    end

    context "with zero value" do
      let(:number) { 0 }

      it "applies opacity-50 class" do
        expect(result).to eq '<span class="opacity-50">0</span>'
      end
    end

    context "with non-zero value" do
      let(:number) { 42 }

      it "does not apply class" do
        expect(result).to eq '<span>42</span>'
      end
    end
  end
end
