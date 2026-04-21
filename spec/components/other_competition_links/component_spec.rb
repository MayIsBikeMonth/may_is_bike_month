# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtherCompetitionLinks::Component, type: :component do
  let!(:competition_2024) { FactoryBot.create(:competition, start_date: Date.new(2024, 5, 1)) }
  let!(:competition_2025) { FactoryBot.create(:competition, start_date: Date.new(2025, 5, 1)) }
  let!(:competition_2026) { FactoryBot.create(:competition, start_date: Date.new(2026, 5, 1)) }
  let(:competitions) { Competition.start_ordered_desc }
  let(:current_competition) { competition_2026 }
  let(:original_view) { false }
  let(:component) do
    render_inline(described_class.new(competitions:, current_competition:, original_view:))
  end

  it "renders competitions in the given order" do
    years = component.css("a, span").map(&:text).map(&:strip).reject(&:empty?)
    expect(years).to eq %w[2026 2025 2024]
  end

  it "links non-current years to competition_path and disables current year" do
    expect(component).to have_css("a.twlink[href='/competitions/#{competition_2024.slug}']", text: "2024")
    expect(component).to have_css("a.twlink[href='/competitions/#{competition_2025.slug}']", text: "2025")
    expect(component).to have_css("span[title=\"You're looking at it\"]", text: "2026")
    expect(component).not_to have_css("a", text: "2026")
  end

  context "when original_view is true" do
    let(:original_view) { true }
    let(:current_competition) { competition_2024 }

    it "links to competitions_original_path" do
      expect(component).to have_css("span[title=\"You're looking at it\"]", text: "2024")
      expect(component).to have_css("a.twlink[href='/competitions_original/2025']", text: "2025")
      expect(component).to have_css("a.twlink[href='/competitions_original/2026']", text: "2026")
    end
  end

  context "with unsaved competitions (stubs for original_view)" do
    let(:competitions) do
      %w[2025 2024].map { |y| Competition.new(start_date: Date.new(y.to_i, 5, 1)) }
    end
    let(:current_competition) { competitions.last }
    let(:original_view) { true }

    it "renders using year without needing a slug" do
      expect(component).to have_css("span[title=\"You're looking at it\"]", text: "2024")
      expect(component).to have_css("a.twlink[href='/competitions_original/2025']", text: "2025")
    end
  end

  context "when multiple competitions exist for the same year" do
    let!(:competition_2025_fall) do
      FactoryBot.create(:competition, start_date: Date.new(2025, 9, 1), end_date: Date.new(2025, 9, 30), display_name: "MIBM Fall 2025")
    end
    let(:current_competition) { competition_2025 }

    it "appends the display name in xs non-bold text inside each link for dup years, marks only the current one" do
      fall_link = component.css("a.twlink[href='/competitions/#{competition_2025_fall.slug}']").first
      suffix = fall_link.at_css("span.text-xs")
      expect(suffix.text).to include "(MIBM Fall 2025)"
      expect(suffix["class"]).to include "font-normal"
      expect(fall_link.text).to include "2025"

      current_span = component.css("span[title=\"You're looking at it\"]").first
      expect(current_span.at_css("span.text-xs").text).to include "(#{competition_2025.display_name})"

      # 2026 has a single competition — no suffix
      year_2026 = component.css("a.twlink[href='/competitions/#{competition_2026.slug}']").first
      expect(year_2026.at_css("span.text-xs")).to be_nil
      expect(year_2026.text.strip).to eq "2026"

      # Only the matching current competition is disabled; the sibling stays clickable.
      expect(component).to have_css("span[title=\"You're looking at it\"]", text: "2025", count: 1)
      expect(component).to have_css("a.twlink[href='/competitions/#{competition_2025_fall.slug}']", text: "2025")
    end
  end
end
