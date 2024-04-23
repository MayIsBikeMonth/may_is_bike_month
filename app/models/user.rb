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
#  strava_username     :string           default(""), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  strava_id           :string
#
class User < ApplicationRecord
  ROLE_ENUM = {basic_user: 0, admin: 1, developer: 2}.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :validatable
  devise :database_authenticatable, :registerable, :trackable, :omniauthable,
    :rememberable

  enum role: ROLE_ENUM

  # def self.friendly_find(str)
  #   if n.is_a?(Integer) || n.match(/\A\d*\z/).present?
  #     where(id: n).first || where(bike_index_id: n).first
  #   else
  #     find_by_email(str)
  #   end
  # end

  # def self.from_omniauth(uid, auth)
  #   user = where(binx_id: uid.to_i).first
  #   user ||= new(binx_id: uid.to_i)
  #   user.email = auth.info.email
  #   user.username = "binx_id#{uid}"
  #   user.password = Devise.friendly_token[0, 20]
  #   user.bike_index_auth = auth.as_json
  #   user.save
  #   user
  # end

  # def self.new_with_session(params, session)
  #   super.tap do |user|
  #     if (data = session["devise.bike_index_email"] && session["devise.bike_index_data"]["extra"]["raw_info"])
  #       user.email = data["email"] if user.email.blank?
  #     end
  #   end
  # end

  def admin_access?
    admin? || developer?
  end
end
