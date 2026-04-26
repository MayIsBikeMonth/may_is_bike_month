class CompetitionsController < ApplicationController
  def show
    @competition = Competition.friendly_find!(params[:id])
    @competition_users = @competition.competition_users_included
      .includes(:user, :competition_activities_included).score_ordered
    @competitions = Competition.start_ordered_desc
    @page_title = @competition.display_name
  end

  def history
    @competitions = Competition.start_ordered_desc
      .includes(competition_users_included: :user)
    @page_title = "Competition history"
  end
end
