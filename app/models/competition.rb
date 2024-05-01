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
  has_many :competition_activities
  has_many :competition_users

  before_validation :set_calculated_attributes

  validates_presence_of :end_date, :start_date, :slug
  validates :end_date, comparison: { greater_than: :start_date }

  def self.current
    where(current: true).last
  end

  def in_period?(time)
    date = time.to_date
    date <= end_date && date >= start_date
  end

  def set_calculated_attributes
    self.end_date ||= start_date + 1.month if start_date.present?
    self.start_date ||= end_date - 1.month if end_date.present?
    self.slug ||= display_name.gsub(/\s/, "-")

    set_current if in_period?(Time.current)
  end

  private

  def set_current
    self.current = true

    Competition.where(current: true).where.not(id: id)
      .update_all(current: false)
  end
end
