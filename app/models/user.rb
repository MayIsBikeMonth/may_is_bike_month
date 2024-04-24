# == Schema Information
#
# Table name: users
#
#  id                  :bigint           not null, primary key
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :string
#  display_name        :string
#  encrypted_password  :string           default(""), not null
#  image_url           :text
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  remember_created_at :datetime
#  role                :integer          default("basic_user")
#  sign_in_count       :integer          default(0), not null
#  strava_auth         :jsonb
#  strava_info         :jsonb
#  strava_username     :string           default(""), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  strava_id           :string
#
class User < ApplicationRecord
  ROLE_ENUM = {basic_user: 0, admin: 1, developer: 2}.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :validatabl
  devise :database_authenticatable, :registerable, :trackable, :omniauthable,
    :rememberable

  enum role: ROLE_ENUM

  before_validation :set_calculated_attributes

  class << self
    def from_omniauth(uid, auth)
      user = where(strava_id: uid.to_i).first || new(strava_id: uid.to_i)
      user.update(password: Devise.friendly_token[0, 20],
        strava_auth: auth["credentials"].as_json.except("expires"),
        strava_info: auth.dig("extra", "raw_info"))
      user
    end

    def new_with_session(params, session)
      super.tap do |user|
        if (data = session["devise.strava_data"] && session["devise.strava_data"]["extra"]["raw_info"])
          user.strava_username = data["id"] if user.strava_id.blank?
        end
      end
    end

    def friendly_find(str)
      if n.is_a?(Integer) || n.match(/\A\d*\z/).present?
        where(id: n).first || where(strava_id: n).first
      else
        find_by_strava_username(str)
      end
    end

    def friendly_find!(str)
      friendly_find(str) || raise(ActiveRecord::RecordNotFound)
    end
  end

  def admin_access?
    admin? || developer?
  end

  def set_calculated_attributes
    self.strava_info ||= {}
    self.strava_username = strava_info["strava_username"]
    self.display_name ||= calculated_name
  end

  private

  def calculated_name
    first_last = [strava_info["first_name"], strava_info["last_name"]].compact.reject(&:blank?).join(" ")
    first_last.present? ? first_last : strava_username
  end
end
