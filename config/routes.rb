require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users, skip: [:registrations], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions_controller: "users/sessions_controller"
  } 
  # do
  #   get 'sign_in', to: redirect("/"), as: :new_user_session
  # end

  root "landing#index"

  resource :account, only: %i[edit update]

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
