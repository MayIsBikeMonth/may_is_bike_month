module ApplicationHelper
  include TranzitoUtils::Helpers

  def number_display(number, round_to: 0)
    content_tag(:span,
      number_with_delimiter(number.to_f.round(round_to)),
      class: ((number == 0) ? "opacity-50" : nil))
  end

  def strava_user_url(user)
    "https://www.strava.com/athletes/#{user.strava_id}"
  end

  # Not the right place for this, but good enuf for now
  def meters_to_feet(number)
    number * 3.28084
  end

  # Not the right place for this, but good enuf for now
  def meters_to_miles(number)
    number / 1609.344
  end
end
