class Avo::Resources::User < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :sign_in_count, as: :number
    field :current_sign_in_at, as: :date_time
    field :last_sign_in_at, as: :date_time
    field :current_sign_in_ip, as: :text
    field :last_sign_in_ip, as: :text
    field :role, as: :select, enum: ::User.roles
    field :strava_username, as: :text
    field :strava_id, as: :text
    field :display_name, as: :text
    field :image_url, as: :textarea
    field :strava_info, as: :text
    field :strava_auth, as: :text
    field :competition_users, as: :has_many
    field :competition_activities, as: :has_many, through: :competition_users
  end
end
