# frozen_string_literal: true

module PunchcardData
  MILE_METERS = 1609.344
  LEVEL_THRESHOLDS_MILES = {1 => 2, 2 => 5, 3 => 10, 4 => 20, 5 => 40}.freeze
  CENTURY_MILES = 100

  module_function

  def daily_metrics(competition_user)
    activities = competition_user.competition_activities_included
    Hash.new { |hash, key| hash[key] = {distance_meters: 0.0, elevation_meters: 0.0} }.tap do |result|
      activities.each do |activity|
        activity.activity_dates_strings.each do |date_string|
          result[date_string][:distance_meters] += activity.distance_meters.to_f
          result[date_string][:elevation_meters] += activity.elevation_meters.to_f
        end
      end
    end
  end

  def level_for(distance_meters)
    miles = distance_meters / MILE_METERS
    LEVEL_THRESHOLDS_MILES.keys.rfind { |level| miles >= LEVEL_THRESHOLDS_MILES[level] }
  end

  def century?(distance_meters)
    distance_meters / MILE_METERS >= CENTURY_MILES
  end
end
