# == Schema Information
#
# Table name: competition_users
#
#  id                      :bigint           not null, primary key
#  display_name            :text
#  included_activity_types :jsonb
#  included_in_competition :boolean          default(FALSE), not null
#  score                   :decimal(, )
#  score_data              :jsonb
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  competition_id          :bigint
#  user_id                 :bigint
#
# Indexes
#
#  index_competition_users_on_competition_id  (competition_id)
#  index_competition_users_on_user_id         (user_id)
#
class CompetitionUser < ApplicationRecord
  BLANK_SCORE = {dates: [], distance: 0, elevation: 0}.freeze
  belongs_to :competition
  belongs_to :user

  has_many :competition_activities
  has_many :competition_activities_included, -> { included_in_competition },
    class_name: "CompetitionActivity"
  has_many :competition_activities_excluded, -> { excluded_from_competition },
    class_name: "CompetitionActivity"

  before_validation :set_calculated_attributes
  validates_uniqueness_of :user_id, scope: [:competition_id], allow_nil: false

  scope :current_competition, -> { joins(:competition).where(competitions: {current: true}) }
  scope :included_in_competition, -> { where(included_in_competition: true) }
  scope :excluded_from_competition, -> { where(included_in_competition: false) }
  scope :included_in_current_competition, -> { included_in_competition.current_competition }
  scope :score_ordered, -> { reorder(score: :desc) }

  class << self
    def score_for(dates:, distance:, **)
      return 0 if dates.none?
      (dates.count + 1 - (1 / distance.to_d))
    end

    def score_hash_for_activities(competition_activities, skip_ids: false)
      # dde_hash = dates_distance_elevation(competition_activities, skip_ids:)
      # dde_hash.merge(score: score_for(**dde_hash))
      dates_distance_elevation(competition_activities, skip_ids:)
    end

    private

    def dates_distance_elevation(competition_activities, skip_ids: false)
      if competition_activities.none?
        BLANK_SCORE.merge(skip_ids ? {} : {ids: []})
      elsif competition_activities.is_a?(ActiveRecord::Relation) # Active record collection
        {
          dates: competition_activities.included_dates_strings,
          distance: competition_activities.sum(:distance_meters), # skip _meters, for space saving
          elevation: competition_activities.sum(:elevation_meters) # skip _meters, for space saving
        }.merge(skip_ids ? {} : {ids: competition_activities.start_ordered.map(&:id)}) # Order IDs so they show up ordered
      else
        raise "competition_activities must be an ActiveRecord::Relation"
      end
    end
  end

  def current_competition?
    competition_id == Competition.current&.id
  end

  def excluded_from_competition?
    !included_in_competition
  end

  def distance_meters
    score_data&.dig("distance") || 0
  end

  def elevation_meters
    score_data&.dig("elevation") || 0
  end

  def activity_dates
    score_data&.dig("dates") || []
  end

  def included_activity_type?(activity_type)
    included_activity_types.include?(activity_type)
  end

  def set_calculated_attributes
    self.display_name ||= user&.display_name
    self.included_activity_types = if included_activity_types.blank?
      competition&.activity_types || Competition::DEFAULT_ACTIVITY_TYPES
    else
      included_activity_types.map(&:strip).reject(&:blank?)
    end.sort
    self.score = score_from_score_data
  end

  def update_score_data!
    update(score_data: calculated_score_data)
    reload
  end

  def calculated_score_data
    self.class.score_hash_for_activities(competition_activities_included, skip_ids: true)
      .merge(periods: competition.periods.map { |period| period.merge(period_score_hash(period)) })
      .as_json
  end

  private

  def score_from_score_data
    return 0 if score_data&.dig("dates").blank?
    self.class.score_for(dates: score_data["dates"], distance: score_data["distance"])
  end

  def period_score_hash(period)
    self.class.score_hash_for_activities(activities_for_period(period))
  end

  def activities_for_period(period)
    competition_activities_included.matching_dates_strings(
      Competition.dates_strings(period[:start_date], period[:end_date])
    )
  end
end
