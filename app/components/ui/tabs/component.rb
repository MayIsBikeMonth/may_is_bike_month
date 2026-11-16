# frozen_string_literal: true

module UI
  module Tabs
    # A row of tabs with its own underline, which the active tab breaks through. A row too
    # wide for the screen scrolls sideways rather than wrapping.
    #
    # tabs: ComponentStructs::Shapes' tabs
    class Component < ApplicationComponent
      # is-active: keys off the aria-current the template sets, and sorts after everything
      # it overrides. The white lower edge is what breaks the row's border, so the tab reads
      # as a tab
      TAB_CLASSES = "twlink -mb-px inline-flex items-baseline gap-1 whitespace-nowrap " \
        "rounded-t-md border border-transparent px-4 py-2 text-sm no-underline " \
        "hover:bg-gray-100 dark:hover:bg-gray-800 is-active:border-gray-300 is-active:border-b-white " \
        "is-active:bg-white is-active:font-semibold is-active:text-gray-900 dark:is-active:border-gray-700 " \
        "dark:is-active:border-b-gray-900 dark:is-active:bg-gray-900 dark:is-active:text-gray-100"

      # turbo: Drive is off app-wide and opted into per element; one data-turbo on the nav
      # covers every tab, since Turbo reads it off the closest ancestor carrying it
      def initialize(tabs:, nav_label:, turbo: false, margin_classes: "mb-3")
        @tabs = tabs
        @nav_label = nav_label
        @turbo = turbo
        @margin_classes = margin_classes
      end

      private

      def link_classes(tab) = [TAB_CLASSES, tab[:classes]].compact.join(" ")
    end
  end
end
