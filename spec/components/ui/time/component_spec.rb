# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Time::Component, type: :component do
  let(:instance) { described_class.new(**options) }
  let(:component) { render_inline(instance) }
  let(:options) { {time:, format:, timezone_if_different:} }
  let(:time) { Time.utc(2024, 1, 15, 14, 30, 0) }
  let(:format) { nil }
  let(:timezone_if_different) { false }

  describe "#render?" do
    context "when time is present" do
      it "renders the component" do
        expect(component).to have_css("span")
      end
    end

    context "when time is nil" do
      let(:time) { nil }

      it "does not render" do
        expect(component).to_not have_css("span")
      end
    end
  end

  describe "rendering content" do
    context "with convert_time format" do
      let(:format) { :convert_time }

      it "renders the time content" do
        expect(component).to have_content("2024-01-15T14:30:00+0000")
        expect(component).to have_css("span.localizeTime")
        expect(component).to_not have_css("span.preciseTime")
      end
    end

    context "with convert_time_precise format" do
      let(:format) { :convert_time_precise }

      it "renders the time content" do
        expect(component).to have_content("2024-01-15T14:30:00+0000")
        expect(component).to have_css("span.localizeTime")
        expect(component).to have_css("span.preciseTime")
      end
    end

    context "with hour format" do
      let(:format) { :hour }
      let(:time) { Time.utc(2025, 8, 5, 14, 0).in_time_zone("Eastern Time (US & Canada)") }

      it "renders the time content" do
        expect(component).to have_content("10am")
      end

      context "when minutes are not zero" do
        let(:time) { Time.utc(2025, 8, 5, 14, 30).in_time_zone("Eastern Time (US & Canada)") }

        it "renders the time content" do
          expect(component).to have_content("10:30am")
        end
      end
    end

    context "with date_hour format" do
      let(:format) { :date_hour }
      let(:time_2024) { Time.utc(2024, 1, 31, 14, 0).in_time_zone("Central Time (US & Canada)") }
      let(:time) { time_2024 }

      it "renders the time content" do
        expect(component).to have_content("Jan 31, 2024, 8am")
      end

      context "when minutes are not zero" do
        let(:time) { time_2024 + 31.minutes }

        it "renders the time content" do
          expect(component).to have_content("Jan 31, 2024, 8:31am")
        end
      end

      context "current_year" do
        let(:time_2024) { Time.utc(Time.current.year, 1, 31, 14, 0).in_time_zone("Central Time (US & Canada)") }

        it "renders the time content" do
          expect(component).to have_content("Jan 31, 8am")
        end
      end
    end

    context "with date format" do
      let(:format) { :date }
      let(:time) { Time.current }

      it "renders the time content" do
        expect(component).to have_content(Time.current.strftime("%B %e"))
      end

      context "2024" do
        let(:time) { Time.utc(2024, 1, 31, 14, 0).in_time_zone("Central Time (US & Canada)") }

        it "renders the time content" do
          expect(component).to have_content("January 31, 2024")
          expect(component).to have_css('[title="January 31, 2024"]')
        end
      end
    end

    context "with default format (nil)" do
      let(:format) { nil }

      it "defaults to convert_time format" do
        expect(component).to have_content("2024-01-15T14:30:00+0000")
      end
    end

    context "with invalid format" do
      let(:format) { :invalid_format }

      it "defaults to convert_time format" do
        expect(component).to have_content("2024-01-15T14:30:00+0000")
      end
    end
  end
end
