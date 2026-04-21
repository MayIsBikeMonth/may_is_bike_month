# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::UserActivitiesForDate::Component, type: :component do
  let(:activities) do
    [
      instance_double(
        CompetitionActivity,
        display_name: "Morning ride",
        strava_url: "https://www.strava.com/activities/123",
        distance_meters: 16_093.44
      ),
      instance_double(
        CompetitionActivity,
        display_name: "Evening spin",
        strava_url: "https://www.strava.com/activities/456",
        distance_meters: 8_046.72
      )
    ]
  end
  let(:component) do
    described_class.new(
      date_string: "2025-05-03",
      activities:,
      punch_id: "sam-2025-05-03",
      competition_year: 2025
    )
  end
  let(:rendered) { render_inline(component) }

  it "renders a container keyed by punch_id, hidden by default, with hanging indent" do
    container = rendered.css("[data-punch-activities-for]").first
    expect(container.attr("data-punch-activities-for")).to eq "sam-2025-05-03"
    expect(container.attr("class")).to include "hidden"
    expect(container.attr("class")).to include "pl-9"
    expect(container.attr("class")).to include "-indent-9"
    expect(container.attr("class")).to include "break-inside-avoid"
  end

  it "shows the short date exactly once" do
    expect(rendered.text.scan("05-03").count).to eq 1
  end

  it "comma-separates the activities" do
    expect(rendered.text).to include ", "
  end

  it "renders each activity as a link to strava" do
    hrefs = rendered.css("a").map { |a| a.attr("href") }
    expect(hrefs).to eq ["https://www.strava.com/activities/123", "https://www.strava.com/activities/456"]
  end

  it "renders imperial and metric distances for each activity" do
    expect(rendered.css(".unit-imperial").map(&:text)).to eq ["10.0 mi", "5.0 mi"]
    expect(rendered.css(".unit-metric").map(&:text)).to eq ["16.1 km", "8.0 km"]
  end
end
