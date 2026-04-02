# frozen_string_literal: true

module UI
  module Modal
    class ComponentPreview < ApplicationComponentPreview
      def default
        render(UI::Modal::Component.new(title: "Settings")) do |modal|
          modal.with_trigger { tag.button("Open Modal", type: "button", data: {action: "click->modal#open"}) }
          modal.with_body { "Modal body content" }
        end
      end
    end
  end
end
