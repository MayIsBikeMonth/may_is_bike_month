require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, skip: [:registrations], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions_controller: "sessions"
  }

  root "landing#index"
  get "/update_strava", to: "landing#update_strava"

  resource :account, only: %i[edit update]

  namespace :admin do
    root to: "competition_users#index"
    resources :competitions, only: %i[index]
    resources :competition_users, only: %i[index edit update]
  end

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
