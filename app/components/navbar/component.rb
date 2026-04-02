# frozen_string_literal: true

module Navbar
  class Component < ApplicationComponent
    def initialize(current_user:, user_root_url: nil, in_admin: false)
      @current_user = current_user
      @user_root_url = user_root_url || "/"
      @admin = in_admin
    end

    private

    def current_page_active?(link_path)
      link_controller = Rails.application.routes.recognize_path(link_path)[:controller]
      Rails.application.routes.recognize_path(helpers.request.url)[:controller] == link_controller
    rescue
      false
    end

    def user_dropdown_options
      options = []
      if @current_user.admin_access?
        options << helpers.link_to("Admin", helpers.admin_root_path)
      end
      options << helpers.button_to("Logout", helpers.destroy_user_session_path, method: :delete, data: {turbo: false})
      options
    end

    def user_dropdown_header
      helpers.link_to(helpers.edit_account_path, class: "block px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-t-lg") do
        helpers.content_tag(:span, @current_user.display_name, class: "block text-sm font-medium text-gray-900 dark:text-white") +
          helpers.content_tag(:span, @current_user.email, class: "block text-xs text-gray-500 dark:text-gray-400 truncate")
      end
    end

    def avatar_button_content
      avatar_url = @current_user.strava_info&.dig("profile_medium")
      if avatar_url.present?
        helpers.image_tag(avatar_url, alt: @current_user.display_name, class: "w-8 h-8 rounded-full object-cover")
      else
        helpers.content_tag(:div, @current_user.display_name.first.upcase,
          class: "w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white text-sm font-medium")
      end
    end
  end
end
