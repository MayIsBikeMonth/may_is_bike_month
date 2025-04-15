module ApplicationHelper
  # include TranzitoUtils::Helpers

  def page_title
    "Something" # originally pulled from tranzito
  end

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

  def competition_activity_display(competition_activity)
    content_tag(:span) do
      concat(competition_activity.display_name)
      if competition_activity.manual_entry? && competition_activity.entered_after_competition_ended?
        concat(" ")
        concat(content_tag(:strong, "?", title: "ignored, manual entry after competition ended"))
      end
    end
  end

  def sortable_params
    @sortable_params ||= sortable_search_params.as_json.map do |k, v|
      # Skip default sort parameters, to reduce unnecessary params
      next if v.blank? || k == "sort" && v == default_column ||
        k == "sort_direction" && v == default_direction
      [k, v]
    end.compact.to_h.with_indifferent_access
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
