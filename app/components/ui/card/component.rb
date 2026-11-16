# frozen_string_literal: true

module UI
  module Card
    class Component < ApplicationComponent
      BACKGROUND_CLASSES = "bg-white dark:bg-gray-800"
      BASE_CLASSES = "#{BACKGROUND_CLASSES} border border-gray-200 dark:border-gray-700"
      # In general don't use small, it looks like a hover state.
      # black is the sticker, which replaces the gray border
      SHADOWS = {
        nil => BASE_CLASSES,
        :small => "#{BASE_CLASSES} shadow-sm",
        :large => "#{BASE_CLASSES} shadow-[0_10px_30px_rgba(44,62,80,.16)]",
        :black => "#{BACKGROUND_CLASSES} border-3 border-[#111] shadow-[4px_4px_0_#111] dark:border-gray-300 dark:shadow-gray-300"
      }.freeze
      # A divided card's rows bring their own padding, so it has none of its own
      DIVIDED_CLASSES = "rounded-xl divide-y divide-gray-200 dark:divide-gray-700"
      UNDIVIDED_CLASSES = "p-4"
      ROUNDED_LG_SHADOWS = %i[large black].freeze

      # divided: separate the direct children with row dividers, for a checklist
      # full_bleed: meet the page's gutter once the .twwiderow holding it is single-column,
      #   and nothing outside such a row
      def initialize(additional_classes: nil, shadow: nil, divided: false, full_bleed: false)
        @shadow_classes = SHADOWS.fetch(shadow) { raise ArgumentError, "unknown shadow #{shadow.inspect}, expected one of: #{SHADOWS.keys.inspect}" }
        @rounded = ROUNDED_LG_SHADOWS.include?(shadow) ? "rounded-lg" : "rounded-sm"
        @additional_classes = additional_classes
        @divided = divided
        @full_bleed = full_bleed
      end

      def call
        content_tag(:div, content, class: card_classes)
      end

      private

      def card_classes
        [@shadow_classes, @divided ? DIVIDED_CLASSES : "#{UNDIVIDED_CLASSES} #{@rounded}",
          ("twfullbleed" if @full_bleed), @additional_classes].compact.join(" ")
      end
    end
  end
end
