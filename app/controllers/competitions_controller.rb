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
    @selected_users = User.find_all_by_slugs(params[:users].to_s.split(","))
    @selectable_users = User.joins(:competition_users)
      .merge(CompetitionUser.included_in_competition).distinct.order(:display_name)
    @page_title = "Competition history"
  end

  def history_users
    users = User.find_all_by_slugs(params[:combobox_values].to_s.split(","))
    render turbo_stream: helpers.combobox_selection_chips_for(users, value: :slug, display: :display_name)
  end
end
