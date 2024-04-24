class SessionsController < Devise::SessionsController
  before_action :send_to_root!, only: [:new, :create, :edit]

  # IDK why this is failing, but -- I don't think it's a vulnerability because it 500s so...
  def send_to_root!
    redirect_to(root_url) && return
  end
end
