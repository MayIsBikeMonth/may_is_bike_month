class SessionsController < Devise::SessionsController
  before_action :send_to_root!, only: [:new, :create, :edit]

  # def new
  # end

  def send_to_root!
    redirect_to(root_url) && return
  end
end
