require "yaml"

# Historical MIBM years that predated this app were tracked in spreadsheets.
# These tasks import the archived totals (per rider, per week) as a legacy
# competition so they show up alongside recent years on the leaderboard.

module RakeLegacy
  METERS_PER_MILE = 1609.344
  METERS_PER_FOOT = 0.3048

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
    expected_weeks = (1..periods.size).map { |n| "week_#{n}" }

    riders.each do |name, weekly|
      unless weekly.is_a?(Hash) && (expected_weeks - weekly.keys).empty?
        raise "#{yaml_path(year)}: #{name} has weeks #{weekly&.keys.inspect}, expected #{expected_weeks.inspect}"
      end

      period_data = periods.each_with_index.map do |period, index|
        week = weekly.fetch(expected_weeks[index])
        period.merge(
          dates: [],
          distance: (week.fetch("miles") * METERS_PER_MILE).round(2),
          elevation: (week.fetch("feet") * METERS_PER_FOOT).round(2),
          ids: []
        )
      end

      total_miles = expected_weeks.sum { |key| weekly[key]["miles"] }
      total_feet = expected_weeks.sum { |key| weekly[key]["feet"] }

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

# Invoke from the command line, quoting the bracketed args so the shell doesn't eat them:
#   bundle exec rake 'legacy:import[2023]'
#   bundle exec rake 'legacy:check_matches[2023]'
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
end
