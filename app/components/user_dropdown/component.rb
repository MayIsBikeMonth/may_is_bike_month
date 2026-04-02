# frozen_string_literal: true

module UserDropdown
  class Component < ApplicationComponent
    def initialize(current_user:, in_admin: false)
      @current_user = current_user
      @in_admin = in_admin
    end

    private

    def signed_in? = @current_user.present?

    def admin_view? = signed_in? && @in_admin

    def admin_access? = @current_user&.admin_access?
  end
end
