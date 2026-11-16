# frozen_string_literal: true

module UI
  module Forms
    module RequiredMarker
      class Component < ApplicationComponent
        def call = tag.span("*", class: "text-red-600", title: "required")
      end
    end
  end
end
