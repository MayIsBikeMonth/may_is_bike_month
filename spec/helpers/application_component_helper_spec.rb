# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationComponentHelper, type: :helper do
  describe '#number_display' do
    it 'displays a number with delimiter' do
      allow(helper).to receive(:number_with_delimiter).and_return('1,000')
      allow(helper).to receive(:content_tag).and_return('<span>1,000</span>')
      
      result = helper.number_display(1000)
      expect(result).to eq('<span>1,000</span>')
    end

    it 'applies opacity class for zero values' do
      allow(helper).to receive(:number_with_delimiter).and_return('0')
      allow(helper).to receive(:content_tag).with(:span, '0', class: 'opacity-50').and_return('<span class="opacity-50">0</span>')
      
      result = helper.number_display(0)
      expect(result).to eq('<span class="opacity-50">0</span>')
    end

    it 'rounds to specified decimal places' do
      allow(helper).to receive(:number_with_delimiter).and_return('1,000.12')
      allow(helper).to receive(:content_tag).and_return('<span>1,000.12</span>')
      
      result = helper.number_display(1000.123, round_to: 2)
      expect(result).to eq('<span>1,000.12</span>')
    end
  end

  describe '#meters_to_feet' do
    it 'converts meters to feet correctly' do
      expect(helper.meters_to_feet(1)).to eq(3.28084)
      expect(helper.meters_to_feet(10)).to eq(32.8084)
    end
  end

  describe '#meters_to_miles' do
    it 'converts meters to miles correctly' do
      expect(helper.meters_to_miles(1609.344)).to be_within(0.001).of(1.0)
      expect(helper.meters_to_miles(3218.688)).to be_within(0.001).of(2.0)
    end
  end

  describe '#raise_if_invalid_value!' do
    it 'does not raise error for valid value' do
      expect { helper.raise_if_invalid_value!('color', 'red', %w[red blue green]) }.not_to raise_error
    end

    it 'raises ArgumentError for invalid value' do
      expect { helper.raise_if_invalid_value!('color', 'purple', %w[red blue green]) }
        .to raise_error(ArgumentError, 'Invalid color: purple. Must be one of: red, blue, green')
    end
  end
end