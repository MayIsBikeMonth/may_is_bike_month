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

  def activity_dates_display(activity_dates)
    if activity_dates.count > 1
      short_date_string_gsub(activity_dates.first)
    else
      activity_dates.map { |d| short_date_string_gsub(d) }.to_sentence
    end
  end

  def check_mark
    "&#x2713;".html_safe
  end

  def cross_mark
    "&#x274C;".html_safe
  end

  def search_emoji
    "🔎"
  end

  private

  def short_date_string_gsub(activity_date)
    activity_date.gsub(/\A\d\d\d\d-/, "")
  end
end
