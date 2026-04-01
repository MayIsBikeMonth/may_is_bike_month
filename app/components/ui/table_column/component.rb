# frozen_string_literal: true

module UI
  module TableColumn
    # ViewComponent representing a single table column. The table renders this
    # component once per cell via `render(col.for_record(record))`.
    class Component < ApplicationComponent
      ARROW_UP = "\u2191"
      ARROW_DOWN = "\u2193"
      NBSP = "\u00A0"

      attr_reader :sortable, :cell_block

      def initialize(label: nil, sortable: nil, classes: nil, header_classes: nil, lower_right: nil, &block)
        @label = label
        @sortable = sortable
        @classes = classes
        @header_classes = header_classes
        @lower_right = lower_right
        @cell_block = block
      end

      # Renders cell content for a record. The block should yield the captured
      # cell content (executed in the parent Table component's view context).
      def render_cell(record)
        cell_content = yield(record)
        return cell_content unless @lower_right

        lower_right_content = @lower_right.call(record)
        content_tag(:div, class: "relative min-h-5") do
          safe_join([
            cell_content,
            content_tag(:small, safe_join([NBSP.html_safe, lower_right_content]),
              class: "absolute -right-0.5 -bottom-1 text-xs text-gray-400")
          ])
        end
      end

      def render_header(render_sortable:, current_sort:, current_direction:, sortable_url:)
        if sortable.present? && render_sortable
          render_sort_link(current_sort:, current_direction:, sortable_url:)
        else
          header_label
        end
      end

      def th_classes(index, total:, bordered:)
        classes = ["px-1 py-2"]
        if bordered
          classes << "border-b border-r border-t border-gray-200 dark:border-gray-600"
          classes << "border-l" if index == 0
        end
        classes << "rounded-tl-sm" if index == 0
        classes << "rounded-tr-sm" if index == total - 1
        classes << @classes if @classes
        classes << @header_classes if @header_classes
        classes.join(" ")
      end

      def td_classes(index, total:, bordered:, last_row:)
        classes = ["px-1 py-1"]
        if bordered
          classes << "border-b border-r border-gray-200 dark:border-gray-700"
          classes << "border-l" if index == 0
        else
          classes << "border-b border-gray-100 dark:border-gray-700"
        end
        classes << "rounded-bl-sm" if last_row && index == 0
        classes << "rounded-br-sm" if last_row && index == total - 1
        classes << @classes if @classes
        classes.join(" ")
      end

      private

      def header_label
        @label || @sortable&.gsub(/_(id|at)\z/, "")&.titleize
      end

      def render_sort_link(current_sort:, current_direction:, sortable_url:)
        title = @label || @sortable.gsub(/_(id|at)\z/, "").titleize
        direction = (@sortable == current_sort && current_direction == "desc") ? "asc" : "desc"
        css = "twlink"

        if @sortable == current_sort
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

        link_to(sortable_url.call(@sortable, direction), class: "#{css} group") do
          safe_join([title, NBSP, *arrow_spans])
        end
      end

      def arrow_for(direction)
        (direction == "desc") ? ARROW_DOWN : ARROW_UP
      end
    end
  end
end
