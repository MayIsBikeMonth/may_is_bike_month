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

  has_many :competition_users
  has_many :competition_users_included, -> { included_in_competition },
    class_name: "CompetitionUser"
  has_many :competition_users_excluded, -> { excluded_from_competition },
    class_name: "CompetitionUser"
  has_many :competition_activities, -> { included_in_competition }, through: :competition_users

  before_validation :set_calculated_attributes

  validates_presence_of :end_date, :start_date, :slug
  validates :end_date, comparison: {greater_than: :start_date}

  def self.current
    where(current: true).last
  end

  def self.period_sundays(start_date, end_date)
    Array(start_date..end_date).select { |date| date.wday == 0 }
  end

  def self.week_start_from_sunday(date)
    monday = date - 6.days
    [monday, date.beginning_of_month].max
  end

  def self.dates_strings(start_date, end_date)
    Array(start_date..end_date).map(&:to_s)
  end

  def create_competition_users
    User.pluck(:id).each do |user_id|
      CompetitionUser.where(competition_id: id, user_id:).first_or_create
    end
  end

  # Method now, could be an attribute later
  def daily_distance_requirement
    3_219 # 2 miles
  end

  # Method now, could be an attribute later
  def activity_types
    DEFAULT_ACTIVITY_TYPES # NOTE: Can be manually specified on CompetitionParticipant
  end

  def in_period?(passed_dates_or_times)
    return false if passed_dates_or_times.blank?
    activity_dates = dates_array_from(passed_dates_or_times)
    if activity_dates.last <= end_date
      activity_dates.last >= start_date
    else
      activity_dates.first < end_date
    end
  end

  # I think this is less performant than the the comparison
  # if it isn't (or isn't much), than maybe #in_period? should use this instead
  def dates_in_period(passed_dates_or_times)
    Array(start_date..end_date) & dates_array_from(passed_dates_or_times)
  end

  # Returns with date strings (rather than Date objects) -
  # Array("2024-05-01".."2024-05-03") => ["2024-05-01", "2024-05-02", "2024-05-03"]
  # NOTE!! this doesn't work between months, e.g. Array("2024-05-29".."2024-06-02")
  def periods
    date_periods = self.class.period_sundays(start_date, end_date)
      .map { |date| {start_date: self.class.week_start_from_sunday(date).to_s, end_date: date.to_s} }

    last_day = Date.parse(date_periods.last[:end_date])
    if last_day != end_date
      date_periods += [{start_date: (last_day + 1).to_s, end_date: end_date.to_s}]
    end
    date_periods
  end

  def set_calculated_attributes
    self.end_date ||= start_date&.end_of_month
    self.start_date ||= end_date&.beginning_of_month
    self.display_name ||= start_date&.year
    self.slug ||= display_name&.gsub(/\s/, "-")

    set_current if in_period?(Time.current.to_date)
  end

  private

  def set_current
    self.current = true

    Competition.where(current: true).where.not(id: id).update_all(current: false)
  end

  def dates_array_from(passed_dates_or_times)
    passed_dates_or_times = passed_dates_or_times.to_date if passed_dates_or_times.is_a?(Time)
    Array(passed_dates_or_times).map(&:to_date)
  end
end
