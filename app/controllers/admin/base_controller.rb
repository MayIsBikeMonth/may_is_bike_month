module Admin
  class BaseController < ApplicationController
    before_action :ensure_user_admin!

    helper_method :user_subject, :competition_subject, :searchable_competitions

    def user_subject
      return @user_subject if defined?(@user_subject)
      user_param = params.permit(:user)[:user]
      @user_subject = if user_param == "current_user"
        current_user
      else
        User.friendly_find(user_param)
      end
    end

    def competition_subject
      return @competition_subject if defined?(@competition_subject)
      competition_params = params.permit(:competition_id, :search_competition_id)
      competition_id = competition_params[:competition_id] || competition_params[:search_competition_id]
      @competition_subject = Competition.friendly_find(competition_id)
    end

    def searchable_competitions
      Competition.order(start_date: :desc)
    end
  end
end
