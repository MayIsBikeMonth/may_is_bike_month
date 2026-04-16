# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtherCompetitionLinks::Component, type: :component do
  let(:competition_2024) { FactoryBot.create(:competition, start_date: Date.new(2024, 5, 1)) }
  let(:competition_2025) { FactoryBot.create(:competition, start_date: Date.new(2025, 5, 1)) }
  let(:competition_2026) { FactoryBot.create(:competition, start_date: Date.new(2026, 5, 1)) }
  let(:competitions) { [competition_2026, competition_2024, competition_2025] }
  let(:current_year) { 2026 }
  let(:original_view) { false }
  let(:component) do
    render_inline(described_class.new(competitions:, current_year:, original_view:))
  end

  it "renders competitions in chronological order" do
    years = component.css("a, span.twlink").map(&:text).map(&:strip)
    expect(years).to eq %w[2024 2025 2026]
  end

  it "links non-current years to competition_path and disables current year" do
    expect(component).to have_css("a.twlink[href='/competitions/#{competition_2024.slug}']", text: "2024")
    expect(component).to have_css("a.twlink[href='/competitions/#{competition_2025.slug}']", text: "2025")
    expect(component).to have_css("span.twlink[title=\"You're looking at it\"]", text: "2026")
    expect(component).not_to have_css("a", text: "2026")
  end

  context "when original_view is true" do
    let(:original_view) { true }
    let(:current_year) { 2024 }

    it "links to competitions_original_path" do
      expect(component).to have_css("span.twlink[title=\"You're looking at it\"]", text: "2024")
      expect(component).to have_css("a.twlink[href='/competitions_original/2025']", text: "2025")
      expect(component).to have_css("a.twlink[href='/competitions_original/2026']", text: "2026")
    end
  end

  context "with unsaved competitions (stubs for original_view)" do
    let(:competitions) do
      %w[2024 2025].map { |y| Competition.new(start_date: Date.new(y.to_i, 5, 1)) }
    end
    let(:current_year) { 2024 }
    let(:original_view) { true }

    it "renders using year without needing a slug" do
      expect(component).to have_css("span.twlink[title=\"You're looking at it\"]", text: "2024")
      expect(component).to have_css("a.twlink[href='/competitions_original/2025']", text: "2025")
    end
  end
end
