# frozen_string_literal: true

module Navbar
  class Component < ApplicationComponent
    def initialize(current_user:)
      @current_user = current_user
    end
  end
end
