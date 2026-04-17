module ApplicationHelper
  include Binxtils::SortableHelper
  include Binxtils::NavHelper

  def page_title
    return @page_title if defined?(@page_title)
    prefix = (in_admin? ? "🧰" : "HeartHeartBeat")
    return "#{prefix} #{@prefixed_page_title}" if @prefixed_page_title.present?
    [
      prefix,
      default_action_name_title,
      controller_title_for_action
    ].compact.join(" ")
  end

  # Not the right place for this, but good enuf for now. Also in ApplicationComponent
  def meters_to_feet(number)
    number * 3.28084
  end

  # Not the right place for this, but good enuf for now. Also in ApplicationComponent
  def meters_to_miles(number)
    number / 1609.344
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

  def in_admin?
    controller_namespace == "admin"
  end

  def active_link(link_text, link_path, html_options = {})
    match_controller = html_options.delete(:match_controller)
    html_options[:class] ||= ""
    html_options[:class] += " active" if current_page_active?(link_path, match_controller)
    link_to(raw(link_text), link_path, html_options).html_safe
  end

  private

  def default_action_name_title
    if action_name == "show"
      # Take up less space for admin
      return in_admin? ? nil : "Display"
    end
    (action_name == "index") ? nil : action_name.titleize
  end

  def controller_title_for_action
    return @controller_display_name if defined?(@controller_display_name)
    # No need to include parking
    c_name = controller_name.gsub("parking_location", "location")
    return c_name.titleize if %(index).include?(action_name)
    c_name.singularize.titleize
  end
end
