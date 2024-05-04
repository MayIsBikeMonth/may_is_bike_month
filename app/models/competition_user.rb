# == Schema Information
#
# Table name: competition_users
#
#  id                      :bigint           not null, primary key
#  included_activity_types :jsonb
#  included_in_competition :boolean          default(FALSE), not null
#  score                   :integer
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

  has_many :competition_activities, -> { included_in_competition }
  has_many :competition_activities_excluded, -> { excluded_in_competition },
    class_name: "CompetitionActivity"

  before_validation :set_calculated_attributes

  scope :included_in_competition, -> { where(included_in_competition: true) }
  scope :excluded_from_competition, -> { where(included_in_competition: false) }

  class << self
    def score_for(dates:, distance:, **)
      return 0 if dates.none?
      (dates.count + 1 - (1 / distance.to_d)).to_f
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
          distance: competition_activities.sum(:distance_meters),
          elevation: competition_activities.sum(:elevation_meters)
        }.merge(skip_ids ? {} : {ids: competition_activities.pluck(:id)})
      else
        raise "competition_activities must be an ActiveRecord::Relation"
        #   {
        #     dates: competition_activities.map(&:activity_dates).flatten.uniq,
        #     distance: competition_activities.map(&:distance_meters).sum,
        #     elevation: competition_activities.map(&:elevation_meters).sum
        #   }.merge(skip_ids ? {} : {ids: competition_activities.map(&:id)})
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
  end

  def calculated_score_data
    self.class.score_hash_for_activities(competition_activities, skip_ids: true)
      .merge(periods: competition.periods.map { |period| period.merge(period_score_hash(period)) })
  end

  private

  def period_score_hash(period)
    self.class.score_hash_for_activities(activities_for_period(period))
  end

  def activities_for_period(period)
    # period_dates = Competition.dates_strings(period[:start_date], period[:end_date])
    # TODO: Can this be done via postgres JSON
    # competition_activities.select do |competition_activity|
    #   (period_dates & competition_activity.activity_dates_strings).any?
    # end
    competition_activities.matching_dates_strings(
      Competition.dates_strings(period[:start_date], period[:end_date])
    )
  end
end
