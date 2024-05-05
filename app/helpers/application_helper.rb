module ApplicationHelper
  include TranzitoUtils::Helpers

  def number_display(number, precision = 0)
    content_tag(:span,
      number_with_delimiter(number.round(precision)),
      class: ((number == 0) ? "less-less-strong" : ""))
  end

  def strava_user_url(user)
    "https://www.strava.com/athletes/#{user.strava_id}"
  end
end
