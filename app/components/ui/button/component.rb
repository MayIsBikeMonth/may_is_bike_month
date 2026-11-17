# frozen_string_literal: true

module UI
  module Button
    # Renders a <button>. For a link styled as a button, or an action button that
    # submits a request to a URL (button_to), use UI::ButtonLink instead — it reuses
    # this component's build_classes, so the two stay visually in lockstep.
    class Component < ApplicationComponent
      BASE_CLASSES = "inline-flex items-center justify-center gap-1.5 cursor-pointer"

      # Per size rather than in BASE_CLASSES, so :callout's radius, border, weight and transition
      # have nothing to tie with
      STANDARD_SHAPE = "rounded-lg border font-medium transition-colors"

      # A press sinks it 2px from where it sits - back down from the hover lift, or below
      # rest on a device that can't hover
      CALLOUT_SHAPE = "rounded-full border-2 font-semibold uppercase tracking-[0.5px] transition-all duration-300 not-disabled:not-aria-disabled:hover:-translate-y-0.5 not-disabled:not-aria-disabled:active:translate-y-0.5 hover:is-active:translate-y-0"

      SIZES = {
        sm: "#{STANDARD_SHAPE} px-2.5 py-1 text-xs",
        md: "#{STANDARD_SHAPE} px-3 py-1.5 text-sm",
        lg: "#{STANDARD_SHAPE} px-4 py-2 text-base",
        callout: "#{CALLOUT_SHAPE} px-10 py-4 text-base",
        callout_sm: "#{CALLOUT_SHAPE} px-6 py-1.5 text-[13px]"
      }.freeze

      # Hover is guarded against both ways an element says it's disabled — :disabled for a
      # button, aria-disabled for UI::ButtonLink's anchor. Nothing else stops it now.
      COLORS = {
        primary: "text-white bg-blue-600 border-blue-600 not-disabled:not-aria-disabled:hover:bg-blue-700 focus:ring-blue-500/40 dark:bg-blue-500 dark:border-blue-500 dark:not-disabled:not-aria-disabled:hover:bg-blue-600",
        secondary: "text-gray-800 bg-white/80 border-gray-200 not-disabled:not-aria-disabled:hover:border-purple-500 not-disabled:not-aria-disabled:hover:bg-purple-50 focus:ring-purple-500/40 dark:bg-gray-800/80 dark:text-gray-100 dark:border-gray-700 dark:not-disabled:not-aria-disabled:hover:border-purple-500 dark:not-disabled:not-aria-disabled:hover:bg-purple-950",
        error: "text-[#c0392b] bg-white border-[#f3c9c9] not-disabled:not-aria-disabled:hover:bg-red-50 focus:ring-red-500/40 dark:bg-transparent dark:text-red-400 dark:border-red-900 dark:not-disabled:not-aria-disabled:hover:bg-red-950",
        purple: "text-white bg-purple-500 border-purple-500 not-disabled:not-aria-disabled:hover:bg-purple-600 not-disabled:not-aria-disabled:hover:border-purple-600 focus:ring-purple-500/40",
        yellow: "text-blue-600 bg-yellow-300 border-yellow-300 not-disabled:not-aria-disabled:hover:bg-yellow-400 not-disabled:not-aria-disabled:hover:border-yellow-400 focus:ring-yellow-300/60",
        link: "twlink rounded-lg p-0 focus:ring-blue-500/40",
        # The grays outrank twlink-underlined's color shift, so each state names its own
        link_gray: "twlink-underlined text-gray-500 not-disabled:not-aria-disabled:hover:text-gray-700 dark:text-gray-400 dark:not-disabled:not-aria-disabled:hover:text-gray-200 rounded-lg p-0 focus:ring-gray-500/40"
      }.freeze

      # Text-only, so they take no size
      LINK_COLORS = %i[link link_gray].freeze

      # The active look, as a delta over COLORS — always emitted alongside it and inert
      # until the element flags itself active (see the is-active variant in application.css,
      # which sorts last, so these override the resting colors with no `!` important).
      # Literal strings so Tailwind's scanner generates them; the spec enforces the prefix.
      #
      # No :link — .twlink states its own active look under the same variant, and a utility
      # here would win over it, so link color would stop following the class it's built from.
      ACTIVE_COLORS = {
        primary: "is-active:bg-blue-800 is-active:ring-2 is-active:ring-blue-500/40 is-active:dark:bg-blue-700",
        secondary: "is-active:text-white is-active:bg-purple-500 is-active:border-purple-500 is-active:ring-2 is-active:ring-purple-500/40",
        error: "is-active:bg-red-100 is-active:border-[#c0392b] is-active:ring-2 is-active:ring-red-500/40 is-active:dark:bg-red-950 is-active:dark:border-red-700",
        purple: "is-active:bg-purple-700 is-active:border-purple-700 is-active:ring-2 is-active:ring-purple-500/40",
        yellow: "is-active:bg-yellow-500 is-active:border-yellow-500 is-active:ring-2 is-active:ring-yellow-300/60",
        link_gray: "is-active:text-gray-900 is-active:dark:text-gray-100"
      }.freeze

      # No pointer-events-none: with pointer events off the browser takes the cursor from
      # underneath, so not-allowed never shows. The aria-disabled half dims ButtonLink's
      # anchor; each half is inert on the element the other covers.
      DISABLED_CLASSES = "disabled:opacity-50 disabled:cursor-not-allowed aria-disabled:opacity-50 aria-disabled:cursor-not-allowed"

      # is-active sorts after focus, so an active button's ring-2 swallows the focus ring
      # unless focus is restated under the variant.
      FOCUS_CLASSES = "focus:outline-none focus:ring-3 is-active:focus:ring-3"

      # Focus and disabled reach the link colors too — only SIZES is button-shaped
      def self.build_classes(color:, size:, html_class: nil)
        extras = [FOCUS_CLASSES, DISABLED_CLASSES]
        extras += [SIZES[size], "no-underline"] unless LINK_COLORS.include?(color)
        [BASE_CLASSES, html_class, *extras, COLORS[color], ACTIVE_COLORS[color]].compact.join(" ")
      end

      # ButtonLink calls this too, so the pair answers a caller the same way
      def self.validate_options!(color:, size:, html_options:)
        raise ArgumentError, "unknown color #{color.inspect}, expected one of: #{COLORS.keys.join(", ")}" unless COLORS.key?(color)
        raise ArgumentError, "size is not supported for link color" if LINK_COLORS.include?(color) && size != :md
        # The component builds its own class, so a passed one is dropped rather than merged
        raise ArgumentError, "class is not supported, you must use the keyword arg html_class" if html_options.key?(:class)
      end

      # name/value are submitted with the form when this button is the one clicked, which
      # is how a form with more than one submit says which was pressed
      def initialize(text: nil, color: :secondary, size: :md, active: false, html_class: nil, spinner: false, name: nil, value: nil, **html_options)
        @text = text
        @name = name
        @value = value
        @color = color
        @active = active
        @html_class = html_class
        @spinner = spinner
        @type = html_options.delete(:type) || "button"
        @data = html_options.delete(:data) || {}
        @html_options = html_options

        @size = SIZES.key?(size) ? size : :md
        self.class.validate_options!(color: @color, size: @size, html_options:)
      end

      # html_options lead, so the component's own attributes can't be overwritten
      def call
        content_tag(:button, safe_join([spinner_span, @text || content].compact), **@html_options, type: @type, class: button_classes, name: @name, value: @value, data: button_data)
      end

      def button_classes
        self.class.build_classes(color: @color, size: @size, html_class: @html_class)
      end

      private

      def button_data
        data = @data.merge(active: @active || nil)
        return data unless @spinner

        data.merge(controller: [data[:controller], "ui--button--submit-spinner"].compact.join(" "))
      end

      # Hidden until the submit-spinner controller reveals it on form submit;
      # no color_class so the svg spins in the button's own text color.
      def spinner_span
        return unless @spinner

        content_tag(:span, render(UI::LoadingSpinner::Component.new(size: :sm, color_class: nil)),
          class: "hidden", data: {"ui--button--submit-spinner-target": "spinner"})
      end
    end
  end
end
