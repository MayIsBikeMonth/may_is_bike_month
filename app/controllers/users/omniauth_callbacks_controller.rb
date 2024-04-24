class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :strava

  def strava
    @user = User.from_omniauth(request.env["omniauth.auth"].uid, request.env["omniauth.auth"])
    if @user.persisted?
      flash[:success] = "Signed in!"
      sign_in_and_redirect @user
    else
      puts request.env["omniauth.auth"]
      flash[:error] = "We're sorry, we failed to sign you in. Ask somebody for help"
      redirect_to root_url
    end
  end
end
