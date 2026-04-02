class AccountsController < ApplicationController
  before_action :redirect_to_root_unless_user_present!

  def edit
  end

  def update
    if params[:user]&.key?(:theme)
      current_user.update!(theme: params[:user][:theme])
      head :ok
      return
    end
  end
end
