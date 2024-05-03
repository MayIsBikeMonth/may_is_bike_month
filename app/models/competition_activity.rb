# == Schema Information
#
# Table name: competition_activities
#
#  id                             :bigint           not null, primary key
#  display_name                   :string
#  distance_meters                :float
#  elevation_meters               :float
#  end_date                       :date
#  included_in_competition        :boolean          default(FALSE), not null
#  moving_seconds                 :integer
#  override_activity_dates_string :string
#  start_at                       :datetime
#  start_date                     :date
#  strava_data                    :jsonb
#  timezone                       :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  competition_user_id            :bigint
#  strava_id                      :string
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

  scope :included_in_competition, -> { where(included_in_competition: true) }
  scope :not_included_in_competition, -> { where(included_in_competition: false) }

  belongs_to :competition_user

  delegate :competition, to: :competition_user, allow_nil: true

  before_validation :set_calculated_attributes

  def self.find_by_strava_data(strava_data)
    find_by(strava_id: strava_data["id"])
  end

  def self.find_or_create_if_valid(competition_user:, strava_data:)
    competition_activity = find_by_strava_data(strava_data)
    if competition_activity.present?
      update_competition_activity_if_changed(strava_data:, competition_activity:)
    else
      create(competition_user:, strava_data:)
    end
  end

  def self.calculated_activity_dates(start_at:, timezone:, moving_seconds:)
    local_start_at = start_at.in_time_zone(timezone)
    local_end_date = (local_start_at + moving_seconds).to_date
    local_start_date = local_start_at.to_date
    if local_start_date == local_end_date
      [local_end_date]
    else
      Array(local_start_at.to_date..local_end_date)
    end
  end

  def self.calculate_end_date(start_at:, timezone:, moving_seconds:)
    calculated_activity_dates(start_at:, timezone:, moving_seconds:).last
  end

  # remove the leading UTC offset
  def self.parse_strava_timezone(string)
    string.gsub(/\([^\)]*\)/, "").strip
  end

  def self.parse_strava_local_time(time_str, timezone)
    # WHY THE FUCK do they put a Z at the end? This time doesn't have a zone :(
    TranzitoUtils::TimeParser.parse(time_str.gsub(/Z\Z/i, ""), timezone)
  end

  def self.strava_attrs_from_data(passed_data)
    timezone = parse_strava_timezone(passed_data["timezone"])
    {
      strava_id: passed_data["id"].to_s,
      timezone: timezone,
      start_at: TranzitoUtils::TimeParser.parse(passed_data["start_date"]),
      display_name: passed_data["name"],
      distance_meters: passed_data["distance"],
      elevation_meters: passed_data["total_elevation_gain"],
      moving_seconds: passed_data["moving_time"]
    }
  end

  def self.update_competition_activity_if_changed(competition_activity:, strava_data:)
    if competition_activity_changed?(competition_activity:, strava_data:)
      competition_activity.update(strava_data:)
      competition_activity.reload
    end

    competition_activity
  end

  # should be private
  def self.competition_activity_changed?(competition_activity:, strava_data:)
    competition_activity.strava_data["distance"].round != strava_data["distance"].round ||
      competition_activity.strava_data["name"] != strava_data["name"] ||
      competition_activity.strava_data["moving_time"] != strava_data["moving_time"] ||
      competition_activity.strava_data["start_date"] != strava_data["start_date"] ||
      competition_activity.strava_data["visibility"] != strava_data["visibility"]
  end

  def strava_type
    strava_data["type"]
  end

  def activity_dates
    return override_activity_dates if override_activity_dates
    (start_date == end_date) ? [start_date] : Array(start_date..end_date)
  end

  def set_calculated_attributes
    self.strava_data = strava_data.except(*IGNORED_STRAVA_KEYS)
    self.attributes = self.class.strava_attrs_from_data(strava_data)
    self.start_date = calculated_start_date
    self.end_date = calculated_end_date
    self.included_in_competition = calculated_included_in_competition
  end

  def calculated_included_in_competition
    INCLUDED_STRAVA_VISIBILITIES.include?(strava_data["visibility"]) &&
      competition_user.included_in_competition? &&
      competition_user.included_activity_type?(strava_type) &&
      competition.in_period?(activity_dates)
  end

  private

  def strava_data_start_date
    self.class.parse_strava_local_time(strava_data["start_date_local"], timezone)
      .to_date
  end

  def strava_data_calculated_end_date
    self.class.calculate_end_date(timezone:, moving_seconds:, start_at: start_at)
  end

  def strava_data_end_date
    s_end_date = strava_data_calculated_end_date
    s_start_date = strava_data_start_date
    # Return the first day if there is only one day, or this activity is below the the daily mileage requirement
    return s_end_date if s_end_date == s_start_date || distance_meters < competition.daily_distance_requirement
    strava_calculated_dates = Array(s_start_date..s_end_date)
    daily_mileages_met = (distance_meters / competition.daily_distance_requirement).floor
    if daily_mileages_met > strava_calculated_dates.count
      strava_calculated_dates.last
    else
      strava_calculated_dates[daily_mileages_met - 1]
    end
  end

  def calculated_start_date
    if override_activity_dates
      override_activity_dates.first
    else
      strava_data_start_date
    end
  end

  def calculated_end_date
    if override_activity_dates
      override_activity_dates.last
    else
      strava_data_end_date
    end
  end

  # override_activity_dates_string overrides the calculated dates from Strava.
  # It accepts:
  # - A comma delineated string of dates
  # - "none" (competition activity counts for no dates, and is included_in_competition: false)
  def override_activity_dates
    return false if override_activity_dates_string.blank?

    return [] if override_activity_dates_string == "none"

    override_activity_dates_string.split(",").map do |str|
      Date.parse(str.strip)
    end
  end
end
