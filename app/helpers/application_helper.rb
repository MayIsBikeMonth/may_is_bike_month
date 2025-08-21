# frozen_string_literal: true

# ApplicationHelper provides shared helper methods for views
module ApplicationHelper
  include ApplicationComponentHelper

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

  def sortable_params
    @sortable_params ||= sortable_search_params.as_json.map do |k, v|
      # Skip default sort parameters, to reduce unnecessary params
      next if v.blank? || (k == "sort" && v == default_column) || (k == "sort_direction" && v == default_direction)

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

  def render_flash_messages
    return if flash.blank?

    kind, text = flash.first

    render(Alert::Component.new(text:, kind:, dismissable: true, margin_classes: "my-2 wrapper-class"))
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

  def current_page_active?(link_path, match_controller = false)
    link_path = Rails.application.routes.recognize_path(link_path)
    active_path = Rails.application.routes.recognize_path(request.url)
    matches_controller = active_path[:controller] == link_path[:controller]
    return true if match_controller && matches_controller

    current_page?(link_path) || matches_controller && active_path[:action] == link_path[:action]
  rescue # This mainly fails in testing - but why not rescue always
    false
  end

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
