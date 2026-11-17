# frozen_string_literal: true

module UI
  module ButtonGroup
    # A row of chips that navigate or act — the link/button counterpart of
    # UI::Forms::RadioButtonGroup, which builds on CHIP_CLASSES and SEGMENT_CLASSES.
    #
    # kind: :toggle renders them as a segmented control instead — one track, with the
    # active entry raised out of it. Where they don't fit on a line, ui--toggle stacks them all.
    class Component < ApplicationComponent
      # Template Dependency: UI::Button::Component
      KINDS = %i[button toggle].freeze

      CHIP_CLASSES = UI::Button::Component.build_classes(color: :secondary, size: :md).freeze

      # UI::PeriodSelect lays its own buttons out with these, so a period row and a chip
      # group line up where they're stacked
      ROW_CLASSES = "flex flex-wrap gap-1"

      # auto-fit needs a definite minimum to count repetitions
      FULL_WIDTH_ROW_CLASSES = "grid grid-cols-[repeat(auto-fit,minmax(4rem,1fr))] gap-2"

      # Track and segment sizes come from kelsey_redesign/new-org-search/, not the type scale
      TRACK_CLASSES = "inline-flex flex-wrap gap-[3px] rounded-[10px] border border-gray-200 " \
        "bg-gray-100 p-[3px] dark:border-gray-700 dark:bg-gray-800"

      # Only what the segment doesn't share with a button — the rest is UI::Button's
      SEGMENT_CLASSES = [
        UI::Button::Component::BASE_CLASSES,
        UI::Button::Component::FOCUS_CLASSES,
        UI::Button::Component::DISABLED_CLASSES,
        # The line height is part of the size: an arbitrary font size pairs none of its own,
        # so the page's inherited 30px made a 24px segment 40px tall
        "rounded-lg px-3 py-[5px] text-[11.5px]/[1.2] font-extrabold whitespace-nowrap transition-colors",
        "justify-start!", # over BASE_CLASSES' centering, once stacked segments are as wide as their track
        "no-underline hover:no-underline text-gray-600 dark:text-gray-400",
        "not-disabled:not-aria-disabled:hover:text-gray-900 dark:not-disabled:not-aria-disabled:hover:text-gray-100",
        "focus:ring-purple-500/40",
        "is-active:bg-white is-active:text-gray-900 is-active:shadow-sm",
        "is-active:dark:bg-gray-900 is-active:dark:text-gray-100"
      ].join(" ").freeze

      # full_width lays the chips out as equal columns that wrap, staying the same width
      # on every line — flex would size each line independently
      def self.group_classes(kind:, full_width:)
        case kind
        when :button
          full_width ? FULL_WIDTH_ROW_CLASSES : ROW_CLASSES
        when :toggle
          # The track sizes itself to its segments, so there's no column layout to widen
          raise ArgumentError, "full_width is not supported for the toggle kind" if full_width

          TRACK_CLASSES
        else
          raise ArgumentError, "unknown kind #{kind.inspect}, expected one of: #{KINDS.join(", ")}"
        end
      end

      def self.group_data(kind:) = (kind == :toggle) ? {controller: "ui--toggle"} : nil

      # entries: ComponentStructs::Shapes' entries
      def initialize(entries:, full_width: false, kind: :button)
        @group_classes = self.class.group_classes(kind:, full_width:)
        @group_data = self.class.group_data(kind:)
        @chip_classes = (kind == :toggle) ? SEGMENT_CLASSES : CHIP_CLASSES
        @entries = entries
      end

      def call
        tag.div(class: @group_classes, data: @group_data) do
          safe_join(@entries.map { |entry| chip(entry) })
        end
      end

      private

      def chip(entry)
        active = entry[:active].presence # false would render data-active="false", nil renders nothing
        # A disabled entry is a <button disabled> even when it has an href — an <a>
        # takes no disabled attribute, so a link would stay live
        href = entry[:disabled] ? nil : entry[:href].presence
        attributes = entry.except(:label, :href, :active).deep_merge(
          class: @chip_classes,
          data: {active:},
          aria: href ? {current: active} : {pressed: active}
        )
        # The chip is inline-flex, so without the span each of a label's text runs and
        # elements becomes a flex item and the whitespace between them collapses.
        label = tag.span(entry[:label].html_safe)

        href ? link_to(label, href, **attributes) : button_tag(label, type: "button", **attributes)
      end
    end
  end
end
