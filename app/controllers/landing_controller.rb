class LandingController < ApplicationController
  def index
    @competition = Competition.current || Competition.create(start_date: Date.parse("2024-5-1"))
    @competition_users = @competition.competition_users_included
      .includes(:user, :competition_activities).score_ordered
    @page_title = "May is Bike Month"
  end

  def update_strava
    if UpdateCompetitionUserJob.enqueue_current
      render json: {message: "success"}
    else
      render json: {message: "No current competition!"}
    end
  end
end
