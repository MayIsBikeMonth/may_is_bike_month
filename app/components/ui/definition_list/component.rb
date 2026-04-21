# frozen_string_literal: true

module UI
  module DefinitionList
    class Component < ApplicationComponent
      renders_many :entries, "Entry"

      def initialize(bordered: false)
        @bordered = bordered
      end

      private

      def dl_classes
        base = "ui-table @md:grid @md:grid-cols-[fit-content(10%)_1fr]"
        @bordered ? "#{base} ui-table-bordered" : base
      end

      class Entry < ApplicationComponent
        def initialize(label:, full_width: false)
          @label = label
          @full_width = full_width
        end

        def call
          tag.div(class: entry_classes) do
            safe_join([
              tag.dt(@label, class: "text-sm font-medium text-gray-900 dark:text-white"),
              tag.dd(content, class: dd_classes)
            ])
          end
        end

        private

        def entry_classes
          base = "px-1 py-1 @md:col-span-2"
          @full_width ? base : "#{base} @md:grid @md:grid-cols-subgrid @md:gap-x-4"
        end

        def dd_classes
          base = "mt-1 text-sm text-gray-700 dark:text-gray-400"
          @full_width ? base : "#{base} @md:mt-0"
        end
      end
    end
  end
end
