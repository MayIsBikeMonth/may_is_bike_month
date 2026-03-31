# frozen_string_literal: true

module UI
  module AlertForErrors
    class ComponentPreview < ApplicationComponentPreview
      def default
        user = User.new
        user.errors.add(:email, "can't be blank")
        user.errors.add(:password, "is too short")
        render(UI::AlertForErrors::Component.new(object: user))
      end
    end
  end
end
