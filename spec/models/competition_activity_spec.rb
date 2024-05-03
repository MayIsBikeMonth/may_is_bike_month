require "rails_helper"

RSpec.describe CompetitionActivity, type: :model do
  let(:strava_data_fixture) { File.read(Rails.root.join("spec", "fixtures", "strava_activity1.json")) }
  let(:strava_data) { JSON.parse(strava_data_fixture) }

  describe "strava_attributes" do
    let(:target_attrs) do
      {
        strava_id: "11319708328",
        timezone: "America/Los_Angeles",
        start_at: Time.at(1714705152),
        display_name: "Rainbow",
        distance_meters: 3611.4,
        elevation_meters: 11.0,
        moving_seconds: 844
      }
    end
    let(:strava_attrs_from_data) { described_class.strava_attrs_from_data(strava_data) }
    it "is expected values" do
      expect(strava_attrs_from_data).to eq target_attrs
    end
  end

  describe "parse_strava_timezone" do
    let(:string) { "(GMT-08:00) America/Los_Angeles" }
    let(:parsed_timezone) { described_class.parse_strava_timezone(string) }

    it "parses" do
      expect(parsed_timezone).to eq "America/Los_Angeles"
    end
  end

  describe "find_or_create_if_valid" do
    let(:start_at) { 1714705152 } # Pulled from the fixture file
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-05-01")) }
    let(:competition_user) { FactoryBot.create(:competition_user, competition: competition) }
    let(:competition_activity) { CompetitionActivity.find_or_create_if_valid(competition_user:, strava_data:) }

    it "creates" do
      expect(competition_activity).to be_valid
      target_strava_data = strava_data.except(*CompetitionActivity::IGNORED_STRAVA_KEYS)
      expect(competition_activity.strava_data).to eq target_strava_data
      expect(competition_activity.distance_meters).to eq 3611.4
      expect(competition_activity.display_name).to eq "Rainbow"
      expect(competition_activity.send(:strava_data_end_date)).to eq Date.parse("2024-5-2")
      expect(competition_activity.activity_dates).to eq([Date.parse("2024-5-2")])

      expect(competition_user.included_in_competition?).to be_truthy

      expect(competition.in_period?(competition_activity.activity_dates)).to be_truthy
      expect(competition_activity.included_in_competition).to be_truthy
    end

    context "with activity in multiple days" do
      let(:base_data) { JSON.parse(strava_data_fixture) }
      let(:strava_data) { base_data.merge("start_date" => "2024-05-03T07:55:12Z") }

      it "creates, only includes the first day" do
        expect(competition_activity).to be_valid
        expect(competition_activity.send(:strava_data_start_date)).to eq Date.parse("2024-5-2")
        expect(competition_activity.send(:strava_data_calculated_end_date)).to eq Date.parse("2024-5-3")
        # NOTE: Different because this activity isn't 2x daily_distance_requirement
        expect(competition_activity.send(:strava_data_end_date)).to eq Date.parse("2024-5-2")
        expect(competition_activity.activity_dates).to eq([Date.parse("2024-5-2")])

        expect(competition.in_period?(competition_activity.activity_dates)).to be_truthy
        expect(competition_activity.included_in_competition).to be_truthy
      end
      context "with activity of sufficient length" do
        let(:strava_data) { base_data.merge("start_date" => "2024-05-03T07:55:12Z", "distance" => 10_000) }
        it "creates and includes both days" do
          expect(competition_activity).to be_valid
          expect(competition_activity.send(:strava_data_start_date)).to eq Date.parse("2024-5-2")
          expect(competition_activity.send(:strava_data_calculated_end_date)).to eq Date.parse("2024-5-3")
          expect(competition_activity.send(:strava_data_end_date)).to eq Date.parse("2024-5-3")

          expect(competition_activity.activity_dates).to eq([Date.parse("2024-5-2"), Date.parse("2024-5-3")])
          expect(competition.in_period?(competition_activity.activity_dates)).to be_truthy
          expect(competition_activity.included_in_competition).to be_truthy
        end
      end
    end

    context "existing activity" do
      it "does not update" do
        expect(CompetitionActivity.competition_activity_changed?(competition_activity:, strava_data:)).to be_falsey
      end
    end
  end

  describe "override_activity_dates" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-5-1")) }
    let(:competition_activity) { FactoryBot.create(:competition_activity, competition:, override_activity_dates_string:) }
    let(:override_activity_dates_string) { nil }
    let(:override_activity_dates) { competition_activity.send(:override_activity_dates) }

    it "is false" do
      expect(competition_activity.send(:calculated_start_date)).to eq Date.parse("2024-5-2")
      expect(competition_activity.start_date).to eq Date.parse("2024-5-2")
      expect(competition_activity.send(:strava_data_calculated_end_date)).to eq Date.parse("2024-5-2")
      expect(competition_activity.send(:calculated_end_date)).to eq Date.parse("2024-5-2")
      expect(competition_activity.end_date).to eq Date.parse("2024-5-2")
      expect(override_activity_dates).to be_falsey
      expect(competition_activity.included_in_competition).to be_truthy
    end

    context "with override_activity_dates_string none" do
      let(:override_activity_dates_string) { "none" }
      it "is empty array" do
        expect(override_activity_dates).to be_truthy
        expect(override_activity_dates).to eq([])
        expect(competition_activity.included_in_competition).to be_falsey
      end
    end

    context "with single override_activity_dates_string" do
      let(:override_activity_dates_string) { "2024-5-1" }
      let(:target) { [Date.parse("2024-5-1")] }
      it "is empty array" do
        expect(override_activity_dates).to be_truthy
        expect(override_activity_dates).to eq target
        expect(competition_activity.activity_dates).to eq target
        expect(competition_activity.included_in_competition).to be_truthy
      end
    end

    context "with multiple override_activity_dates_string" do
      let(:override_activity_dates_string) { "2024-5-1, 2024-5-3" }
      let(:target) { [Date.parse("2024-5-1"), Date.parse("2024-5-3")] }
      it "is empty array" do
        expect(override_activity_dates).to be_truthy
        expect(override_activity_dates).to eq(target)
        expect(competition_activity.activity_dates).to eq target
        expect(competition_activity.included_in_competition).to be_truthy
      end
    end
  end

  describe "strava_data_start_date" do
    let(:competition_activity) { CompetitionActivity.new(strava_data: {start_date_local:}, timezone: timezone) }
    let(:start_date_local) { "2024-05-02T19:59:12Z" }
    let(:timezone) { "America/Los_Angeles" }
    let(:strava_start_date) { competition_activity.send(:strava_data_start_date) }

    it "calculates" do
      # If you parse this time as if it's in UTC, you get 5-3
      expect(strava_start_date).to eq Date.parse("2024-5-2")
      expect(described_class.parse_strava_local_time(start_date_local, timezone).to_i).to eq 1714705152
    end

    context "UTC" do
      let(:timezone) { "UTC" }
      it "calculates" do
        expect(strava_start_date).to eq Date.parse("2024-5-2")
        expect(described_class.parse_strava_local_time(start_date_local, timezone).to_i).to eq 1714679952
      end
    end

    context "with different timezone" do
      let(:timezone) { "Asia/Hong_Kong" }
      it "calculates" do
        expect(strava_start_date).to eq Date.parse("2024-5-2")
        expect(described_class.parse_strava_local_time(start_date_local, timezone).to_i).to eq 1714651152
      end
    end
  end
end
