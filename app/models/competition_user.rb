# == Schema Information
#
# Table name: competition_users
#
#  id                      :bigint           not null, primary key
#  included_activity_types :jsonb
#  included_in_competition :boolean          default(FALSE), not null
#  score                   :float
#  score_data              :jsonb
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  competition_id          :bigint
#  user_id                 :bigint
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

  scope :included_in_competition, -> { where(included_in_competition: true) }
  scope :excluded_from_competition, -> { where(included_in_competition: false) }
  scope :included_in_current_competition, -> {
    included_in_competition.joins(:competition).where(competitions: {current: true})
  }
  scope :score_ordered, -> { reorder(score: :desc) }

  delegate :display_name, to: :user, allow_nil: true

  class << self
    def score_for(dates:, distance:, **)
      return 0 if dates.none?
      (dates.count + (1 / distance.to_d)).to_f
    end

    def score_hash_for_activities(competition_activities, skip_ids: false)
      dde_hash = dates_distance_elevation(competition_activities, skip_ids:)
      dde_hash.merge(score: score_for(**dde_hash))
    end

    private

    def dates_distance_elevation(competition_activities, skip_ids: false)
      if competition_activities.none?
        BLANK_SCORE.merge(skip_ids ? {} : {ids: []})
      elsif competition_activities.is_a?(ActiveRecord::Relation) # Active record collection
        {
          dates: competition_activities.pluck(:activity_dates_strings).flatten.uniq,
          distance: competition_activities.sum(:distance_meters), # skip _meters, for space saving
          elevation: competition_activities.sum(:elevation_meters) # skip _meters, for space saving
        }.merge(skip_ids ? {} : {ids: competition_activities.pluck(:id)})
      else
        raise "competition_activities must be an ActiveRecord::Relation"
      end
    end
  end

  def excluded_from_competition?
    !included_in_competition
  end

  def included_activity_type?(activity_type)
    included_activity_types.include?(activity_type)
  end

  def set_calculated_attributes
    self.included_activity_types = if included_activity_types.blank?
      competition&.activity_types || Competition::DEFAULT_ACTIVITY_TYPES
    else
      included_activity_types.map(&:strip).reject(&:blank?)
    end
    self.score = score_data&.dig("score") || 0
  end

  def update_score_data!
    update(score_data: calculated_score_data)
  end

  def calculated_score_data
    self.class.score_hash_for_activities(competition_activities_included, skip_ids: true)
      .merge(periods: competition.periods.map { |period| period.merge(period_score_hash(period)) })
      .as_json
  end

  private

  def period_score_hash(period)
    self.class.score_hash_for_activities(activities_for_period(period))
  end

  def activities_for_period(period)
    competition_activities_included.matching_dates_strings(
      Competition.dates_strings(period[:start_date], period[:end_date])
    )
  end
end
