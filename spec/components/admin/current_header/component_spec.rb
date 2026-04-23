# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CurrentHeader::Component, type: :component do
  let(:default_options) do
    {
      viewing: "Competition users",
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

  it "renders the h1 and graph toggle" do
    expect(component).to be_present

    expect(component.css("h1").text.strip).to eq "Admin Competition Users"
    expect(component.css("a").map(&:text)).to include("graph")
    expect(component.css("a[href*='render_chart=true']")).to be_present
    expect(component.css("p").first.text).to match(/0\s+Competition users\s+for all competitions/)
  end

  context "with a chart_collection of two records" do
    let!(:competition_users) { FactoryBot.create_list(:competition_user, 2) }
    let(:options) { default_options.merge(chart_collection: CompetitionUser.all) }

    it "renders the count with pluralized viewing" do
      expect(component.css("p").first.text).to match(/2\s+Competition users\s+for all competitions/)
    end
  end

  context "with a chart_collection of one record" do
    let!(:competition_user) { FactoryBot.create(:competition_user) }
    let(:options) { default_options.merge(chart_collection: CompetitionUser.all) }

    it "uses the singular form" do
      expect(component.css("p").first.text).to match(/1\s+Competition user\s+for all competitions/)
    end
  end

  context "with a content block" do
    let(:component) do
      with_request_url("/admin/competition_users") do
        render_inline(instance) { "New Competition".html_safe }
      end
    end

    it "renders the block alongside the graph toggle" do
      expect(component.to_html).to include("New Competition")
      expect(component.css("a").map(&:text)).to include("graph")
    end
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
      expect(component.css("a.active").map(&:text)).to include("graph")
    end
  end
end
