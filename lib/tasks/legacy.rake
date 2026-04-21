require "csv"

# Historical MIBM years that predated this app were tracked in spreadsheets.
# These tasks import the archived totals (per name, per week) as a legacy
# competition so they show up alongside recent years on the leaderboard.

module RakeLegacy
  METERS_PER_MILE = 1609.344
  METERS_PER_FOOT = 0.3048

  DUMMY_STRAVA_PREFIX = "legacy-dummy-"

  def self.csv_path(year)
    Rails.root.join("db/seeds/legacy_competition_#{year}.csv")
  end

  def self.load_rows(year)
    path = csv_path(year)
    raise "CSV not found: #{path}" unless File.exist?(path)
    CSV.read(path, headers: true).map do |row|
      {name: row["name"], week: row["week"].to_i, miles: row["miles"].to_f, feet: row["feet"].to_f}
    end
  end

  def self.import(year:, source_url:)
    rows = load_rows(year)
    grouped = rows.group_by { |r| r[:name] }
    competition = Competition.find_or_initialize_by(start_date: Date.new(year, 5, 1), kind: :legacy)
    competition.update!(
      end_date: Date.new(year, 5, 31),
      legacy_url: source_url
    )

    periods = competition.periods
    expected_weeks = (1..periods.size).to_a

    grouped.each do |name, entries|
      by_week = entries.index_by { |e| e[:week] }
      missing = expected_weeks - by_week.keys
      extra = by_week.keys - expected_weeks
      raise "#{csv_path(year)}: #{name} is missing weeks #{missing.inspect}" if missing.any?
      raise "#{csv_path(year)}: #{name} has unexpected weeks #{extra.inspect} (competition has #{periods.size})" if extra.any?

      period_data = periods.each_with_index.map do |period, index|
        entry = by_week[index + 1]
        period.merge(
          dates: [],
          distance: (entry[:miles] * METERS_PER_MILE).round(2),
          elevation: (entry[:feet] * METERS_PER_FOOT).round(2),
          ids: []
        )
      end

      total_miles = expected_weeks.sum { |w| by_week[w][:miles] }
      total_feet = expected_weeks.sum { |w| by_week[w][:feet] }

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

    grouped.size
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
    names = load_rows(year).map { |r| r[:name] }.uniq
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
  desc "Import an archived MIBM year from db/seeds/legacy_competition_<year>.csv (idempotent)"
  task :import, [:year, :source_url] => :environment do |_, args|
    count = RakeLegacy.import(year: args[:year].to_i, source_url: args[:source_url])
    puts "Imported #{count} legacy #{args[:year]} rows"
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
