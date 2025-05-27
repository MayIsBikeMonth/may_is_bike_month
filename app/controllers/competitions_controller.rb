class CompetitionsController < ApplicationController
  def show
    @competition = Competition.friendly_find!(params[:id])
    @competition_users = @competition.competition_users_included
      .includes(:user, :competition_activities).score_ordered
    @page_title = "May is Bike Month #{@competition}"
    @skip_wrapper_class = true
  end
end
