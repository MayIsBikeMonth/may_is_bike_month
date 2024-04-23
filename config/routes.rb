require "sidekiq/web"

Rails.application.routes.draw do
  root "landing#index"

  # authenticate :user, lambda { |u| u.admin? } do
  mount Sidekiq::Web, at: "/sidekiq"
  # end
end
