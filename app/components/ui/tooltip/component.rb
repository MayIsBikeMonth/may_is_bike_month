# frozen_string_literal: true

module UI
  module Tooltip
    class Component < ApplicationComponent
      TRIGGER_ACTIONS = "mouseenter->ui--tooltip#showOnHover mouseleave->ui--tooltip#hideOnHover " \
        "focusin->ui--tooltip#showPersistent click->ui--tooltip#showPersistent " \
        "focusout->ui--tooltip#hideOnFocusout"

      TRIGGER_CLASS = "inline-block rounded cursor-help " \
        "focus:outline-none focus:ring-3 focus:ring-blue-500/40"

      BUTTON_CLASS = "keep-with-previous inline-flex items-center justify-center h-4 w-4 rounded-full " \
        "bg-gray-200 text-gray-700 hover:bg-gray-300 " \
        "dark:bg-white/10 dark:text-gray-200 dark:hover:bg-white/20 " \
        "text-2xs font-bold cursor-help " \
        "focus:outline-none focus:ring-3 focus:ring-blue-500/40"

      SURFACE_CLASS = "bg-white border-gray-200 dark:bg-gray-800 dark:border-gray-700"

      renders_one :body
      renders_one :tooltip_button, ->(**attrs, &block) {
        tag.button(**trigger_attrs(class: BUTTON_CLASS, **attrs)) { block ? capture(&block) : "?" }
      }

      def initialize(text: nil)
        @text = text
      end

      # The controller and its hover/focus actions live on the wrapping span so
      # the trigger and the tooltip are siblings — a link in the tooltip body
      # can't be nested inside the trigger button.
      def call
        tag.span(class: "inline-block", data: {controller: "ui--tooltip", action: TRIGGER_ACTIONS}) do
          safe_join([trigger, tooltip_span], " ")
        end
      end

      private

      # With no trigger content, fall back to the "?" button — the default way
      # tooltips are rendered.
      def trigger
        return tooltip_button if tooltip_button?
        return tag.button(**trigger_attrs(class: BUTTON_CLASS)) { "?" } if content.blank?

        tag.button(**trigger_attrs(class: TRIGGER_CLASS)) { content }
      end

      def trigger_attrs(data: {}, **extra_attrs)
        {
          type: "button",
          "aria-label": @text.presence,
          "aria-describedby": tooltip_id,
          data: {"ui--tooltip-target": "trigger", **data},
          **extra_attrs
        }
      end

      def tooltip_id
        @tooltip_id ||= "tooltip-#{SecureRandom.hex(4)}"
      end

      def tooltip_body
        body? ? body : @text
      end

      # The controller drops pointer-events-none once the tooltip is held open
      def tooltip_span
        tag.span(
          safe_join([tooltip_body, arrow_span]),
          role: "tooltip",
          id: tooltip_id,
          data: {"ui--tooltip-target": "tooltip"},
          class: "twtext-color hidden pointer-events-none whitespace-normal w-max max-w-[min(24rem,90vw)] rounded text-left " \
            "px-2 py-1 font-sans text-xs font-normal normal-case border shadow-lg #{SURFACE_CLASS}"
        )
      end

      # The controller positions it and picks which two borders show
      def arrow_span
        tag.span(
          "aria-hidden": true,
          data: {"ui--tooltip-target": "arrow"},
          class: "absolute h-2 w-2 rotate-45 border-solid #{SURFACE_CLASS}"
        )
      end
    end
  end
end
