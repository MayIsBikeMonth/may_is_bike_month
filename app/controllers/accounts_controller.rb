class AccountsController < ApplicationController
  before_action :redirect_to_root_unless_user_present!

  def show
    redirect_to root_url, status: :see_other
  end

  def edit
  end

  def update
    if params[:user]&.key?(:theme)
      current_user.update!(theme: params[:user][:theme])
    elsif params[:user]&.key?(:unit) && params[:user][:unit].in?(User::UNIT_ENUM.keys.map(&:to_s))
      current_user.update!(unit: params[:user][:unit])
    end
    head :ok
  end
end
