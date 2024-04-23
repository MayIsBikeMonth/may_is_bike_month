class User < ApplicationRecord
  ROLE_ENUM = {basic_user: 0, admin: 2, developer: 1}.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable, :omniauthable, :recoverable, :rememberable, :validatable

  enum role: ROLE_ENUM
end
