# == Schema Information
#
# Table name: competition_activities
#
#  id                      :bigint           not null, primary key
#  display_name            :string
#  distance_meters         :float
#  elevation_meters        :float
#  end_date                :date
#  included_in_competition :boolean          default(FALSE), not null
#  moving_seconds          :integer
#  start_at                :datetime
#  start_date              :date
#  strava_data             :jsonb
#  timezone                :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  competition_user_id     :bigint
#  strava_id               :string
#
class CompetitionActivity < ApplicationRecord
  IGNORED_STRAVA_KEYS = %w[
    laps
    map
    segment_efforts
    splits_metric
    splits_standard
    stats_visibility
  ].freeze
  INCLUDED_STRAVA_VISIBILITIES = %w[everyone followers_only].freeze

  belongs_to :competition_user

  before_validation :set_calculated_attributes

  def self.find_by_strava_data(strava_data)
    find_by(strava_id: strava_data["id"])
  end

  def self.find_or_create_if_valid(competition_user:, strava_data:)
    competition_activity = find_by_strava_data(strava_data)
    if competition_activity.present?
      update_competition_activity_if_changed(competition_user:, strava_data:, competition_activity:)
    else
      create(competition_user:, strava_data:)
    end
  end

  def self.activity_dates(start_at:, timezone:, move_seconds:)
    local_start_at = start_at.in_time_zone(timezone).to_date
    local_end_at = local_start_at + moving_seconds.to_date
    [local_start_at..local_end_at]
  end

  def self.calculate_end_date(start_at:, timezone:, move_seconds:)
    activity_dates(start_at:, timezone:, move_seconds:).last
  end

  def include_in_competition?(competition_user:, strava_data:)
    INCLUDED_STRAVA_VISIBILITY.include?(strava_data["visibility"]) &&
      competition_user.included_in_competition? &&
      competition_user.included_activity_type?(strava_data["type"]) &&
      competition_user.competition.included_distance?(strava_data["distance"]) &&
      competition_user.competition.in_period?(strava_data["start_date_local"])
  end

  # should be private?
  def self.update_competition_activity_if_changed(competition_user:, strava_data:, competition_activity:)
    unless round(competition_activity.distance_meters) == round(strava_data["distance_meter"]) &&
      competition_activity.display_name == strava_data["name"] &&
      competition_activity.included_in_competition == include_in_competition?(competition_user:, strava_data:)

      competition_activity.update(strava_data:)
      competition_activity.reload
    end

    competition_activity
  end

  private

  def set_calculated_attributes
    self.include_in_competition = competition_user.include_in_competition
    self.strava_data = strava_data.except(*IGNORED_STRAVA_KEYS)
    self.attributes = strava_attrs_from_data(strava_data)
    self.included_in = include_in_competition?(competition_user:, strava_data:)
  end

  def strava_attrs_from_data(passed_data)
    start_at = TimeParser.parse(passed_data["start_date"])
    start_date = TimeParser.parse(passed_data["start_date_local"]).to_date

    timezone = parse_strava_timezone(passed_data["timezone"])

    {
      strava_id: "#{passed_data["id"]}",
      start_date: start_date,
      end_date: self.class.calculate_end_date(start_at:, timezone:, move_seconds: passed_data["moving_time"]),
      timezone: timezone,
      start_at: start_at,
      display_name: passed_data["name"],
      distance_meters: passed_data["distance"],
      elevation_meters: passed_data["total_elevation_gain"],
      moving_seconds: passed_data["moving_time"]
    }
  end

  def parse_strava_timezone(string)
    string.gsub(/\([^\)]*\)/, "").strip
  end
end
