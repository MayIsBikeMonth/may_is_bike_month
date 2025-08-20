# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationComponent, type: :component do
  let(:component) { ApplicationComponent.new }

  describe "number_display" do
    let(:target) { "<span>1</span>" }
    
    it "renders" do
      rendered = render_inline(component) { |c| c.number_display(1) }
      expect(rendered.to_html).to include target
    end
    
    context "with round_to" do
      let(:target) { "<span>1.0</span>" }
      
      it "renders" do
        rendered = render_inline(component) { |c| c.number_display(1, round_to: 1) }
        expect(rendered.to_html).to include target
      end
    end
  end

  describe "unit conversion methods" do
    it "converts meters to feet" do
      expect(component.meters_to_feet(100)).to eq(328.084)
    end

    it "converts meters to miles" do
      expect(component.meters_to_miles(1609.344)).to eq(1.0)
    end
  end

  describe "unit class methods" do
    context "when initial_unit is metric" do
      before { component.instance_variable_set(:@initial_unit, "metric") }

      it "returns visible metric class" do
        expect(component.unit_class_metric).to eq("unit-metric ")
      end

      it "returns hidden imperial class" do
        expect(component.unit_class_imperial).to eq("unit-imperial hidden")
      end
    end

    context "when initial_unit is imperial" do
      before { component.instance_variable_set(:@initial_unit, "imperial") }

      it "returns hidden metric class" do
        expect(component.unit_class_metric).to eq("unit-metric hidden")
      end

      it "returns visible imperial class" do
        expect(component.unit_class_imperial).to eq("unit-imperial ")
      end
    end
  end

  describe "raise_if_invalid_value!" do
    it "does not raise when value is in options" do
      expect { component.raise_if_invalid_value!("test", "valid", ["valid", "invalid"]) }.not_to raise_error
    end

    it "raises ArgumentError when value is not in options" do
      expect { component.raise_if_invalid_value!("test", "invalid", ["valid", "other"]) }.to raise_error(ArgumentError, "Invalid test: invalid. Must be one of: valid, other")
    end
  end
end