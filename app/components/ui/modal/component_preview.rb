# frozen_string_literal: true

module UI
  module Modal
    class ComponentPreview < ApplicationComponentPreview
      def default
        render(UI::Modal::Component.new(title: "Settings")) do |modal|
          modal.with_trigger { "Open Modal" }
          modal.with_body { "Modal body content" }
        end
      end
    end
  end
end
