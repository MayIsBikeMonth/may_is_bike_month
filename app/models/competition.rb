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

  def set_calculated_attributes
    self.end_date ||= start_date + 1.month if start_date.present?
    self.start_date ||= end_date - 1.month if end_date.present?
    self.slug ||= display_name.gsub(/\s/, "-")
  end
end
