# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::PeriodSelect::Component, type: :component do
  let(:start_time) { Time.zone.local(2024, 5, 1, 12, 0) }
  let(:end_time) { Time.zone.local(2024, 5, 8, 12, 0) }
  let(:period) { "all" }
  let(:include_future) { false }
  let(:prepend_text) { nil }
  let(:instance) do
    described_class.new(period:, start_time:, end_time:, include_future:, prepend_text:)
  end
  let(:component) do
    with_request_url("/admin/users") { render_inline(instance) }
  end

  it "renders the default past-period buttons and a custom toggle" do
    expect(component).to have_css('[role="group"]')
    expect(component).to have_link("hour")
    expect(component).to have_link("day")
    expect(component).to have_link(text: /7 days/)
    expect(component).to have_link(text: /30 days/)
    expect(component).to have_link("year")
    expect(component).to have_link("All")
    expect(component).to have_button(text: /custom/)
  end

  it "hides next_week and next_month by default" do
    expect(component).to have_css('a[data-period="hour"]')
    expect(component).not_to have_css('a[data-period="next_week"]')
    expect(component).not_to have_css('a[data-period="next_month"]')
  end

  it "marks the active period with ring styling" do
    instance = described_class.new(period: "week", start_time:, end_time:)
    result = with_request_url("/admin/users") { render_inline(instance) }
    week_link = result.css('a[data-period="week"]').first
    day_link = result.css('a[data-period="day"]').first
    expect(week_link["class"]).to include("ring-2")
    expect(day_link["class"]).not_to include("ring-2")
  end

  it "links each period button to a URL with the period param" do
    expect(component).to have_css('a[data-period="hour"][href*="period=hour"]')
    expect(component).to have_css('a[data-period="all"][href*="period=all"]')
  end

  context "when include_future" do
    let(:include_future) { true }

    it "renders next_week and next_month buttons" do
      expect(component).to have_css('a[data-period="next_week"]')
      expect(component).to have_css('a[data-period="next_month"]')
    end
  end

  context "when prepend_text given" do
    let(:prepend_text) { "Created during:" }

    it "renders the leading label" do
      expect(component).to have_text("Created during:")
    end
  end

  describe "custom form visibility" do
    context "when period is not custom" do
      let(:period) { "week" }

      it "renders the custom form with hidden class" do
        form = component.css("form[data-collapse-target='content']").first
        expect(form).to be_present
        expect(form["class"]).to include("hidden")
      end
    end

    context "when period is custom" do
      let(:period) { "custom" }

      it "renders the custom form without hidden class" do
        form = component.css("form[data-collapse-target='content']").first
        expect(form).to be_present
        expect(form["class"]).not_to include("hidden")
      end

      it "prefills datetime inputs with start_time and end_time" do
        expect(component).to have_css('input[name="start_time_selector"][value="2024-05-01T12:00"]')
        expect(component).to have_css('input[name="end_time_selector"][value="2024-05-08T12:00"]')
      end
    end
  end

  describe "stimulus wiring" do
    it "binds the custom button to the collapse toggle action" do
      expect(component).to have_css('button[data-action*="click->collapse#toggle"]')
    end

    it "binds the custom form submit to the period-select submit action" do
      expect(component).to have_css('form[data-action*="submit->ui--period-select#submit"]')
    end
  end
end
