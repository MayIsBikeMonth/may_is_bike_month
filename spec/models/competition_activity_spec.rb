require "rails_helper"

RSpec.describe CompetitionActivity, type: :model do
  let(:strava_data_fixture) { File.read(Rails.root.join("spec", "fixtures", "strava_activity1.json")) }
  let(:strava_data) { JSON.parse(strava_data_fixture) }

  describe "factory" do
    let(:competition) { FactoryBot.create(:competition, start_date: Time.parse("2024-05-01")) }
    let(:start_at) { Time.at(1714779274) }
    let(:competition_activity) do
      FactoryBot.create(:competition_activity,
        strava_type: "Handcycle",
        competition:,
        elevation_meters: 42,
        strava_id: "2322x",
        distance_meters: 43,
        moving_seconds: 666,
        start_at: start_at,
        timezone: "America/Chicago")
    end

    it "sets strava_data from the passed values" do
      expect(competition_activity).to be_valid
      expect(competition_activity.reload.strava_type).to eq "Handcycle"
      expect(competition_activity.competition.id).to eq competition.id
      expect(competition_activity.elevation_meters).to eq 42
      expect(competition_activity.strava_id).to eq "2322"
      expect(competition_activity.distance_meters).to eq 43
      expect(competition_activity.moving_seconds).to eq 666
      expect(competition_activity.start_at.to_i).to eq start_at.to_i
      expect(competition_activity.timezone).to eq "America/Chicago"
      expect(competition_activity.included_in_competition).to be_truthy
    end
  end

  describe "strava_attributes" do
    let(:target_attrs) do
      {
        strava_id: "11319708328",
        timezone: "America/Los_Angeles",
        start_at: Time.at(1714705152),
        display_name: "Rainbow",
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
        expect(CompetitionActivity.matching_dates_strings(["2024-05-02", "2024-05-03"]).pluck(:id)).to eq([competition_activity.id])
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
      context "with activity overlapping start" do
        let(:strava_data) do
          base_data.merge("start_date" => "2024-05-01T02:59:12Z",
            "start_date_local" => "2024-04-30T19:59:12Z",
            "distance" => 30_000,
            "moving_time" => 432000) # 5 days
        end

        it "creates and includes both days" do
          expect(competition_activity).to be_valid
          expect(competition_activity.send(:strava_data_start_date)).to eq Date.parse("2024-4-30")
          expect(competition_activity.send(:strava_data_calculated_end_date)).to eq Date.parse("2024-5-5")
          expect(competition_activity.send(:strava_data_end_date)).to eq Date.parse("2024-5-5")

          expect(competition_activity.activity_dates).to eq(Array(Date.parse("2024-5-1")..Date.parse("2024-5-5")))
          expect(competition_activity.start_date).to eq Date.parse("2024-5-1")
          expect(competition.in_period?(competition_activity.activity_dates)).to be_truthy
          expect(competition_activity.included_in_competition).to be_truthy

          expect(CompetitionActivity.matching_dates_strings(["2024-05-01"]).pluck(:id)).to eq([competition_activity.id])
          expect(CompetitionActivity.matching_dates_strings(["2024-05-01", "2024-05-07"]).pluck(:id)).to eq([competition_activity.id])
          expect(CompetitionActivity.matching_dates_strings(["2024-04-30"]).pluck(:id)).to eq([])
        end
      end
    end

    context "existing activity" do
      it "does not update" do
        expect(CompetitionActivity.send(:competition_activity_changed?, competition_activity:, strava_data:)).to be_falsey
      end
    end
  end

  describe "override_activity_dates" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-5-1")) }
    let(:competition_activity) { FactoryBot.create(:competition_activity, competition:, override_activity_dates_strings:) }
    let(:override_activity_dates_strings) { nil }
    let(:override_activity_dates) { competition_activity.send(:override_activity_dates) }

    it "is false" do
      expect(competition_activity.start_date).to eq Date.parse("2024-5-2")
      expect(competition_activity.send(:strava_data_calculated_end_date)).to eq Date.parse("2024-5-2")
      expect(competition_activity.end_date).to eq Date.parse("2024-5-2")

      expect(override_activity_dates).to be_falsey
      expect(competition_activity.included_in_competition).to be_truthy
    end

    context "with override_activity_dates_strings none" do
      let(:override_activity_dates_strings) { [] }

      it "is empty array" do
        expect(override_activity_dates).to be_truthy
        expect(override_activity_dates).to eq([])
        expect(competition_activity.excluded_from_competition?).to be_truthy
      end
    end

    context "with single override_activity_dates_strings" do
      let(:override_activity_dates_strings) { ["2024-5-1"] }
      let(:target) { [Date.parse("2024-5-1")] }

      it "is empty array" do
        expect(override_activity_dates).to be_truthy
        expect(override_activity_dates).to eq target
        expect(competition_activity.activity_dates).to eq target
        expect(competition_activity.included_in_competition).to be_truthy
      end
    end

    context "with multiple override_activity_dates_strings" do
      let(:override_activity_dates_strings) { ["2024-5-1", "2024-5-3"] }
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

  describe "manual_entry?" do
    let(:competition) { FactoryBot.create(:competition, start_date: Time.parse("2024-05-01")) }
    let(:competition_user) { FactoryBot.create(:competition_user, competition:) }
    let(:strava_data_json) { '{"id":11582104480,"name":"MIBM to 555","type":"Ride","manual":true,"athlete":{"id":7097811,"resource_state":1},"commute":false,"flagged":false,"gear_id":"b11587114","private":false,"trainer":false,"distance":7000.7,"pr_count":0,"timezone":"(GMT-08:00) America/Los_Angeles","max_speed":0,"upload_id":null,"end_latlng":[],"has_kudoed":false,"sport_type":"Ride","start_date":"2024-05-21T15:49:00Z","utc_offset":-25200.0,"visibility":"everyone","external_id":null,"kudos_count":0,"moving_time":1791,"photo_count":0,"elapsed_time":1791,"start_latlng":[],"workout_type":10,"athlete_count":1,"average_speed":3.909,"comment_count":0,"has_heartrate":false,"location_city":null,"location_state":null,"resource_state":2,"location_country":"United States","start_date_local":"2024-05-21T08:49:00Z","achievement_count":0,"from_accepted_tag":false,"heartrate_opt_out":false,"total_photo_count":0,"total_elevation_gain":112.5,"display_hide_heartrate_option":false}' }
    let(:strava_data) { JSON.parse(strava_data_json) }
    let(:competition_activity) { CompetitionActivity.find_or_create_if_valid(competition_user:, strava_data:) }

    it "is manual_entry? and is entered_after_competition_ended? has 0 distance" do
      expect(competition_activity).to be_valid
      expect(competition_activity.manual_entry?).to be_truthy
      expect(competition_activity.entered_after_competition_ended?).to be_truthy
      expect(competition_activity.strava_distance_meters).to eq 7000.7
      expect(competition_activity.distance_meters).to eq 0
      expect(competition_activity.activity_dates).to eq([Date.parse("2024-5-21")])
    end

    context "created_at before end of competition" do
      it "has strava_distance_meters of distance_meters" do
        competition_activity.update(created_at: competition.end_date.end_of_day)
        expect(competition_activity).to be_valid
        expect(competition_activity.manual_entry?).to be_truthy
        expect(competition_activity.entered_after_competition_ended?).to be_falsey
        expect(competition_activity.strava_distance_meters).to eq 7000.7
        expect(competition_activity.distance_meters).to eq 7000.7
        expect(competition_activity.activity_dates).to eq([Date.parse("2024-5-21")])
      end
    end
  end
end
