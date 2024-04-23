module ApplicationHelper
  include TranzitoUtils::Helpers

  # def page_title
  #   prefix = in_admin? ? "🧰" : nil
  #   return [prefix, @page_title].compact.join(" ") if defined?(@page_title)
  #   suffix = in_admin? ? nil : "— Convus"
  #   return "#{@page_title_prefix} #{suffix}" if @page_title_prefix.present?
  #   [
  #     prefix,
  #     [action_display_name, controller_display_name].compact.join(" - "),
  #     suffix
  #   ].compact.join(" ")
  # end
end
