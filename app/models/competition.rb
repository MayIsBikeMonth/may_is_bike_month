# == Schema Information
#
# Table name: competitions
#
#  id           :bigint           not null, primary key
#  current      :boolean
#  display_name :string
#  end_date     :date
#  slug         :string
#  start_date   :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Competition < ApplicationRecord
  DEFAULT_ACTIVITY_TYPES = %w[Ride Velomobile Handcycle].freeze

  has_many :competition_activities
  has_many :competition_users

  before_validation :set_calculated_attributes

  validates_presence_of :end_date, :start_date, :slug
  validates :end_date, comparison: { greater_than: :start_date }

  def self.current
    where(current: true).last
  end

  # Method now, could be an attribute later
  def daily_mileage_requirement
    3219
  end

  # Method now, could be an attribute later
  def activity_types
    DEFAULT_ACTIVITY_TYPES
  end

  def in_period?(passed_dates_or_times)
    return false if passed_dates_or_times.blank?
    passed_dates_or_times = passed_dates_or_times.to_date if passed_dates_or_times.is_a?(Time)
    activity_dates = Array(passed_dates_or_times).map(&:to_date)
    if activity_dates.last <= end_date
      activity_dates.last >= start_date
    else
      activity_dates.first < end_date
    end
  end

  def set_calculated_attributes
    self.end_date ||= start_date + 1.month if start_date.present?
    self.start_date ||= end_date - 1.month if end_date.present?
    self.slug ||= display_name.gsub(/\s/, "-")

    set_current if in_period?(Time.current.to_date)
  end

  private

  def set_current
    self.current = true

    Competition.where(current: true).where.not(id: id)
      .update_all(current: false)
  end
end
