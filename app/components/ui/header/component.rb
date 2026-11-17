# frozen_string_literal: true

module UI
  module Header
    class Component < ApplicationComponent
      TAG_CLASSES = {h1: "text-2xl", h2: "text-xl", h3: "text-lg"}.freeze

      def initialize(text: nil, subtitle: nil, tag: :h1, html_class: nil)
        @text = text
        @subtitle = subtitle
        @tag = tag
        @html_class = html_class
      end

      def call
        heading = content_tag(@tag, heading_text, class: header_classes)
        return heading if @subtitle.blank?

        safe_join([heading,
          content_tag(:p, @subtitle, class: "mb-6 text-sm text-gray-500 dark:text-gray-400")])
      end

      private

      # An empty heading renders as an invisible, unannounced landmark rather than failing
      def heading_text
        @text.presence || content.presence ||
          raise(ArgumentError, "text: or block content is required")
      end

      def header_classes
        [TAG_CLASSES.fetch(@tag), @subtitle.present? ? "mb-1" : "mb-6",
          "font-extrabold tracking-tight text-gray-900 dark:text-gray-100",
          @html_class].compact.join(" ")
      end
    end
  end
end
