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
#  strava_username     :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  strava_id           :string
#
class User < ApplicationRecord
  include FriendlyFindable

  ROLE_ENUM = {basic_user: 0, admin: 1, developer: 2}.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :validatabl
  devise :database_authenticatable, :registerable, :trackable, :omniauthable,
    :rememberable

  enum :role, ROLE_ENUM

  has_many :competition_users
  has_many :competition_activities, through: :competition_users

  before_validation :set_calculated_attributes
  after_commit :update_current_competition_user

  class << self
    def stored_strava_auth(auth_cred)
      cred = auth_cred.as_json.except("expires", "token_type", "expires_in")
      return cred if cred["access_token"].blank?
      cred.except("access_token").merge("token" => cred["access_token"])
    end

    def valid_strava_auth?(auth)
      return false if auth.blank?
      stored_strava_auth(auth).slice("token", "expires_at", "refresh_token").values
        .count { |v| v.present? } == 3
    end

    def from_omniauth(uid, auth)
      user = where(strava_id: uid.to_i).first || new(strava_id: uid.to_i)

      user.update(password: Devise.friendly_token[0, 20],
        strava_auth: stored_strava_auth(auth["credentials"]),
        strava_info: auth.dig("extra", "raw_info"))
      user
    end

    def new_with_session(params, session)
      super.tap do |user|
        if (data = session["devise.strava_data"] && session["devise.strava_data"]["extra"]["raw_info"])
          user.strava_username = data["username"] if user.strava_username.blank?
        end
      end
    end

    # Override FriendlyFindable
    def friendly_find_slug(str = nil)
      return nil if str.blank?
      find_by_display_name(str) || find_by_strava_username(str)
    end
  end

  def current_competition_user
    competition_users.current_competition.last
  end

  def strava_auth_needs_refresh?
    strava_auth["expires_at"].to_i < (Time.current.to_i + 2)
  end

  def admin_access?
    admin? || developer?
  end

  def active_strava_token
    raise "Invalid strava auth" unless self.class.valid_strava_auth?(strava_auth)
    refresh_strava_token! if strava_auth_needs_refresh?
    strava_auth["token"]
  end

  def set_calculated_attributes
    self.strava_info ||= {}
    self.strava_username = strava_info["username"] if strava_info["username"].present?
    self.display_name ||= calculated_name
  end

  # Bust cache
  def update_current_competition_user
    current_competition_user&.touch
  end

  def strava_user_url
    "https://www.strava.com/athletes/#{strava_id}"
  end

  private

  def refresh_strava_token!
    refresh_response = StravaIntegration.refresh_access_token(strava_auth["refresh_token"])
    if self.class.valid_strava_auth?(refresh_response[:json])
      update!(strava_auth: self.class.stored_strava_auth(refresh_response[:json]))
      reload
    else
      raise "invalid strava response: #{refresh_response}"
    end
  end

  def calculated_name
    first_last = [strava_info["firstname"], strava_info["lastname"]].reject(&:blank?).join(" ")
    first_last.present? ? first_last : strava_username
  end
end
