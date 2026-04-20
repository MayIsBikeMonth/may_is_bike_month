# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CurrentHeader::Component, type: :component do
  let(:default_options) do
    {
      viewing: "competition_users",
      include_competition_select: true,
      competition_subject: nil,
      searchable_competitions: Competition.order(start_date: :desc),
      render_period: false,
      s_params: {}
    }
  end
  let(:options) { default_options }
  let(:instance) { described_class.new(**options) }
  let(:component) { with_request_url("/admin/competition_users") { render_inline(instance) } }

  it "renders the graph toggle" do
    expect(component).to be_present

    expect(component.css("a").map(&:text)).to include("graph")
    expect(component.css("a[href*='render_chart=true']")).to be_present
  end

  context "with include_competition_select: false" do
    let(:options) { default_options.except(:include_competition_select) }

    it "still renders the graph toggle" do
      expect(component.css("a").map(&:text)).to include("graph")
    end
  end

  context "with render_chart: true and chart_collection" do
    let(:options) do
      default_options.merge(
        render_chart: true,
        chart_collection: CompetitionUser.all,
        time_range: 1.week.ago..Time.current,
        time_range_column: "created_at"
      )
    end

    it "renders the chart and flips render_chart to false on toggle" do
      expect(component.css("a[href*='render_chart=false']")).to be_present
      expect(component.css("a.font-bold").map(&:text)).to include("graph")
    end
  end
end
