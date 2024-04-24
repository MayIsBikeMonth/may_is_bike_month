require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, skip: [:registrations], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions_controller: "sessions"
  } 

  root "landing#index"

  resource :account, only: %i[edit update]

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
