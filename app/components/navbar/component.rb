# frozen_string_literal: true

module Navbar
  class Component < ApplicationComponent
    NavItem = Data.define(:label, :path)

    def initialize(current_user:)
      @current_user = current_user
    end

    private

    def nav_items
      [
        NavItem.new("Competitions", helpers.admin_competitions_path),
        NavItem.new("Competition Users", helpers.admin_competition_users_path),
        NavItem.new("Competition Activities", helpers.admin_competition_activities_path),
        NavItem.new("Users", helpers.admin_users_path),
        NavItem.new("Strava Requests", helpers.admin_strava_requests_path)
      ]
    end

    def current_nav_item
      nav_items.find { |item| helpers.current_page_active?(item.path, true) }
    end
  end
end
