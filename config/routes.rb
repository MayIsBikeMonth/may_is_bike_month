require "sidekiq/web"

Rails.application.routes.draw do
  # authenticate :user, lambda { |u| u.admin? } do
  mount Sidekiq::Web, at: "/sidekiq"
  # end
end
