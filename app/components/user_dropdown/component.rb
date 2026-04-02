# frozen_string_literal: true

module UserDropdown
  class Component < ApplicationComponent
    def initialize(current_user:, in_admin: false)
      @signed_in = current_user.present?
      @current_user = current_user || User.new
      @in_admin = in_admin
    end

    private

    def signed_in? = @signed_in

    def admin_view? = signed_in? && @in_admin

    def admin_access? = @current_user&.admin_access?

    def avatar_url = @current_user.strava_info&.dig("profile_medium")

    def avatar_content
      if avatar_url.present?
        helpers.image_tag(avatar_url, alt: @current_user.display_name, class: "w-7 h-7 rounded-full object-cover")
      else
        helpers.content_tag(:div, @current_user.display_name.first.upcase,
          class: "w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white text-xs font-medium")
      end
    end
  end
end
