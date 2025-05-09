# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompetitionTable::UserRow::Component, type: :component do
  let(:options) { {} }
  let(:component) { render_inline(described_class.new(**options)) }

  xit "renders" do
    expect(component).to be_present
  end
end
