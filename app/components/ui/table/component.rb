# frozen_string_literal: true

module UI
  module Table
    class Component < ApplicationComponent
      include SortableHelper

      ARROW_UP = "\u2191"
      ARROW_DOWN = "\u2193"
      NBSP = "\u00A0"

      Column = Data.define(:label, :sortable, :block, :classes)

      # Pass cache_key to enable per-row fragment caching (e.g. cache_key: "admin-users").
      def initialize(records:, cache_key: nil, classes: nil, unbordered: false, sort: nil, sort_direction: nil)
        @records = records
        @cache_key = cache_key
        @classes = classes
        @bordered = !unbordered
        @sort = sort
        @sort_direction = sort_direction || "desc"
        @columns = []
      end

      def column(label: nil, sortable: nil, classes: nil, &block)
        @columns << Column.new(label:, sortable:, block:, classes:)
        nil
      end

      def before_render
        content
      end

      private

      def current_sort
        @sort || (helpers.respond_to?(:sort_column) ? helpers.sort_column : nil)
      end

      def current_direction
        @sort_direction || (helpers.respond_to?(:sort_direction) ? helpers.sort_direction : nil)
      end

      def render_sortable(column)
        title = column.gsub(/_(id|at)\z/, "").titleize
        direction = (column == current_sort && current_direction == "desc") ? "asc" : "desc"
        css = "twlink"

        if column == current_sort
          css += " active"
          arrow_spans = [
            content_tag(:span, arrow_for(current_direction), class: "group-hover:hidden"),
            content_tag(:span, arrow_for(direction), class: "hidden group-hover:inline opacity-50")
          ]
        else
          arrow_spans = [
            content_tag(:span, arrow_for(direction), class: "opacity-0 group-hover:opacity-50 transition-opacity")
          ]
        end

        link_to(sortable_url(column, direction), class: "#{css} group") do
          safe_join([title, NBSP, *arrow_spans])
        end
      end

      def arrow_for(direction)
        (direction == "desc") ? ARROW_DOWN : ARROW_UP
      end

      def first_col?(index) = index == 0
      def last_col?(index) = index == @columns.length - 1

      def th_classes(col, index)
        classes = ["px-1 py-2"]
        if @bordered
          classes << "border-b border-r border-t border-gray-200 dark:border-gray-600"
          classes << "border-l" if first_col?(index)
        end
        classes << "rounded-tl-sm" if first_col?(index)
        classes << "rounded-tr-sm" if last_col?(index)
        classes << col.classes if col.classes
        classes.join(" ")
      end

      def td_classes(col, index, last_row:)
        classes = ["px-1 py-1"]
        if @bordered
          classes << "border-b border-r border-gray-200 dark:border-gray-700"
          classes << "border-l" if first_col?(index)
        else
          classes << "border-b border-gray-100 dark:border-gray-700"
        end
        classes << "rounded-bl-sm" if last_row && first_col?(index)
        classes << "rounded-br-sm" if last_row && last_col?(index)
        classes << col.classes if col.classes
        classes.join(" ")
      end

      def table_classes
        [
          "min-w-full text-left border-separate border-spacing-0",
          @classes
        ].compact.join(" ")
      end
    end
  end
end
