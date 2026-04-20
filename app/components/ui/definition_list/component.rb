# frozen_string_literal: true

module UI::DefinitionList
  class Component < ApplicationComponent
    renders_many :entries, "Entry"

    def initialize(bordered: false)
      @bordered = bordered
    end

    private

    def dl_classes
      base = "ui-table md:grid md:grid-cols-[fit-content(10%)_1fr]"
      @bordered ? "#{base} ui-table-bordered" : base
    end

    class Entry < ApplicationComponent
      def initialize(label:)
        @label = label
      end

      def call
        tag.div(class: "px-1 py-1 md:col-span-2 md:grid md:grid-cols-subgrid md:gap-x-6") do
          safe_join([
            tag.dt(@label, class: "text-sm font-medium text-gray-900 dark:text-white"),
            tag.dd(content, class: "mt-1 md:mt-0 text-sm text-gray-700 dark:text-gray-400")
          ])
        end
      end
    end
  end
end
