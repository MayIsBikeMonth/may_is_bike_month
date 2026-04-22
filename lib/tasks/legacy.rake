require "yaml"

# Historical MIBM years that predated this app were tracked in spreadsheets.
# These tasks import the archived totals (per rider, per week) as a legacy
# competition so they show up alongside recent years on the leaderboard.

module RakeLegacy
  METERS_PER_MILE = 1609.344
  METERS_PER_FOOT = 0.3048

  DUMMY_STRAVA_PREFIX = "legacy-dummy-"

  def self.yaml_path(year)
    Rails.root.join("db/seeds/legacy_competition_#{year}.yml")
  end

  def self.load_data(year)
    path = yaml_path(year)
    raise "Legacy data not found: #{path}" unless File.exist?(path)
    YAML.safe_load_file(path, permitted_classes: [Date])
  end

  def self.import(year:)
    data = load_data(year)
    riders = data.fetch("riders")
    competition = Competition.find_or_initialize_by(start_date: Date.new(year, 5, 1), kind: :legacy)
    competition.update!(
      end_date: Date.new(year, 5, 31),
      legacy_url: data["source_url"]
    )

    periods = competition.periods

    riders.each do |name, weekly|
      unless weekly.is_a?(Array) && weekly.size == periods.size
        raise "#{yaml_path(year)}: #{name} has #{weekly&.size.inspect} weeks, expected #{periods.size}"
      end

      period_data = periods.each_with_index.map do |period, index|
        miles, feet = weekly[index]
        period.merge(
          dates: [],
          distance: (miles * METERS_PER_MILE).round(2),
          elevation: (feet * METERS_PER_FOOT).round(2),
          ids: []
        )
      end

      total_miles = weekly.sum { |pair| pair[0] }
      total_feet = weekly.sum { |pair| pair[1] }

      score_data = {
        dates: [],
        distance: (total_miles * METERS_PER_MILE).round(2),
        elevation: (total_feet * METERS_PER_FOOT).round(2),
        ids: [],
        periods: period_data
      }.as_json

      user = LegacyUserFinder.find_or_create(name)
      competition_user = CompetitionUser.find_or_initialize_by(competition:, user:)
      competition_user.update!(
        included_in_competition: true,
        display_name: name,
        score_data:
      )
    end

    competition.competition_users.find_each do |cu|
      UpdateCompetitionUserJob.perform_async(cu.id)
    end

    riders.size
  end

  def self.dummy_activities(year:)
    competition = Competition.find_by(start_date: Date.new(year, 5, 1), kind: :legacy)
    raise "No #{year} legacy competition found — run legacy:import[#{year}] first" unless competition

    CompetitionActivity
      .joins(:competition_user)
      .where(competition_users: {competition_id: competition.id})
      .where("strava_id LIKE ?", "#{DUMMY_STRAVA_PREFIX}%")
      .destroy_all

    created = 0

    competition.competition_users.find_each do |competition_user|
      period_data = competition_user.score_data&.dig("periods") || []

      period_data.each_with_index do |period, period_index|
        distance = period["distance"].to_f
        next if distance <= 0

        elevation = period["elevation"].to_f
        splits = [(distance / 45_000.0).ceil, 1].max
        per_distance = distance / splits
        per_elevation = elevation / splits
        period_start = Date.parse(period["start_date"])
        period_end = Date.parse(period["end_date"])
        days_in_period = (period_end - period_start).to_i + 1

        splits.times do |split_index|
          day_offset = (days_in_period * split_index / splits.to_f).floor
          activity_date = period_start + day_offset
          strava_id = "#{DUMMY_STRAVA_PREFIX}#{competition_user.id}-#{period_index}-#{split_index}"
          moving_seconds = (per_distance / 5.5).round
          start_date = "#{activity_date}T09:30:00Z"

          CompetitionActivity.create!(
            competition_user:,
            strava_data: {
              "id" => strava_id,
              "name" => "#{competition_user.display_name} ride",
              "distance" => per_distance,
              "moving_time" => moving_seconds,
              "total_elevation_gain" => per_elevation,
              "elapsed_time" => moving_seconds,
              "type" => "Ride",
              "timezone" => "UTC",
              "start_date" => start_date,
              "start_date_local" => start_date,
              "visibility" => "everyone"
            }
          )
          created += 1
        end
      end
    end

    created
  end

  def self.check_matches(year:)
    names = load_data(year).fetch("riders").keys
    unmatched = names.reject { |name| LegacyUserFinder.find(name) }
    if unmatched.empty?
      puts "All #{names.size} legacy names matched existing users."
      return
    end

    width = unmatched.map(&:length).max + 4
    puts "Unmatched names:"
    puts
    unmatched.each do |name|
      matches = LegacyUserFinder.potential_matches(name)
      label = matches.any? ? "potential matches: #{matches.join(", ")}" : "no potential matches"
      puts "#{name.ljust(width)}#{label}"
    end
  end
end

namespace :legacy do
  desc "Import an archived MIBM year from db/seeds/legacy_competition_<year>.yml (idempotent)"
  task :import, [:year] => :environment do |_, args|
    count = RakeLegacy.import(year: args[:year].to_i)
    puts "Imported #{count} legacy #{args[:year]} riders"
  end

  desc "Dry-run: report legacy names for <year> that wouldn't match an existing user"
  task :check_matches, [:year] => :environment do |_, args|
    RakeLegacy.check_matches(year: args[:year].to_i)
  end

  desc "Create dummy CompetitionActivities for a legacy <year> competition (idempotent)"
  task :dummy_activities, [:year] => :environment do |_, args|
    count = RakeLegacy.dummy_activities(year: args[:year].to_i)
    puts "Created #{count} dummy legacy activities"
  end
end
