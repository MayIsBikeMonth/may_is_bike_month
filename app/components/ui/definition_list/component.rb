# frozen_string_literal: true

module UI::DefinitionList
  class Component < ApplicationComponent
    renders_many :entries, "Entry"

    class Entry < ApplicationComponent
      def initialize(label:)
        @label = label
      end

      def call
        tag.div(class: "col-span-2 grid grid-cols-subgrid gap-x-6 py-4") do
          safe_join([
            tag.dt(@label, class: "text-sm font-medium text-gray-900 dark:text-white"),
            tag.dd(content, class: "text-sm text-gray-700 dark:text-gray-400")
          ])
        end
      end
    end
  end
end
