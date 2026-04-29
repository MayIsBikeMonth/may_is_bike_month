# frozen_string_literal: true

# General helper methods shared with View Components
module ApplicationComponentHelper
  def number_display(number, round_to: 0)
    content_tag(:span,
      number_with_delimiter(number.to_f.round(round_to)),
      class: ((number == 0) ? "opacity-50" : nil))
  end

  def check_mark
    "&#x2713;".html_safe
  end

  def cross_mark
    "&#x274C;".html_safe
  end

  def strava_link(user)
    return nil if user.strava_id.blank?
    link_to(user.strava_username.presence || user.strava_id, user.strava_user_url, target: "_blank", class: "twlink")
  end
end
