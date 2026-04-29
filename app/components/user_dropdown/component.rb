# frozen_string_literal: true

module UserDropdown
  class Component < ApplicationComponent
    def initialize(current_user:)
      @signed_in = current_user.present?
      @current_user = current_user || User.new
    end

    private

    def avatar_url
      url = @current_user.strava_info&.dig("profile_medium")
      url if url&.start_with?("http")
    end

    def avatar_content
      if avatar_url.present?
        helpers.image_tag(avatar_url, alt: @current_user.display_name, class: "w-7 h-7 rounded-full object-cover")
      else
        helpers.content_tag(:div, @current_user.display_name.first.upcase,
          class: "w-7 h-7 rounded-full bg-purple-500 flex items-center justify-center text-white text-xs font-medium")
      end
    end
  end
end
