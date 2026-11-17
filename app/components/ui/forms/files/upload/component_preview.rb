# frozen_string_literal: true

module UI
  module Forms
    module Files
      module Upload
        class ComponentPreview < ApplicationComponentPreview
          def default
            {template: "ui/forms/files/upload/component_preview/default"}
          end
        end
      end
    end
  end
end
