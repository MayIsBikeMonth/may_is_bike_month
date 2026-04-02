class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Devise::Controllers::Rememberable

  skip_before_action :verify_authenticity_token, only: :strava

  def strava
    @user = User.from_omniauth(request.env["omniauth.auth"].uid, request.env["omniauth.auth"])
    @competition = Competition.current
    if @competition.present?
      @user.competition_users.where(competition_id: @competition.id).first_or_create
    end

    if @user.persisted?
      apply_signup_preferences(@user)
      remember_me(@user)

      flash[:success] = "Signed in!"
      sign_in_and_redirect @user, event: :authentication
    else
      puts request.env["omniauth.auth"]
      flash[:error] = "We're sorry, we failed to sign you in. Ask somebody for help"
      redirect_to root_url
    end
  end

  private

  def apply_signup_preferences(user)
    attrs = {}
    theme = cookies.delete(:signup_theme)
    attrs[:theme] = (theme == "dark") ? :theme_dark : :theme_light if theme.present?
    unit = cookies.delete(:signup_unit)
    attrs[:unit] = unit if unit.present?
    user.update(attrs) if attrs.present?
  end
end
