require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, skip: [:registrations], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions_controller: "sessions"
  }

  root "landing#index"
  get "/update_strava", to: "landing#update_strava"

  resource :account, only: %i[edit update]

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end

  # devise_config = ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
end
