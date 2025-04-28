# frozen_string_literal: true

# should replace _revised_messages.html.haml
module Alert
  class Component < ApplicationComponent
    KINDS = %i[notice error warning success]
    # TODO: Should this convert danger>error, notice>warning? Do we need those anymore, from some bootstrap thing?

    # NOTE: you can pass arbitrary classes in via margin_classes, but that's not ideal (they might conflict, etc)
    def initialize(text: nil, kind: nil, dismissable: false, margin_classes: "mb-4")
      @text = text
      @kind = if KINDS.include?(kind&.to_sym)
        kind&.to_sym
      else
        KINDS.first
      end
      @dismissable = dismissable
      @margin_classes = margin_classes
    end

    private

    def color_classes
      case @kind
      when :notice
        "text-blue-800 bg-blue-50 dark:bg-gray-800 dark:text-blue-400 " \
        "border-blue-300 dark:border-blue-800"
      when :error
        "text-red-800 bg-red-50 dark:bg-gray-800 dark:text-red-400 " \
        "border-red-300 dark:border-red-800"
      when :warning
        "text-yellow-800 bg-yellow-50 dark:bg-gray-800 dark:text-yellow-400 " \
        "border-yellow-300 dark:border-yellow-800"
      when :success
        "text-green-800 bg-green-50 dark:bg-gray-800 dark:text-green-400 " \
        "border-green-300 dark:border-green-800"
      end
    end

    def dismissable_color_classes
      case @kind
      when :notice
        "bg-blue-50 focus:ring-blue-400 hover:bg-blue-200 dark:bg-gray-800 dark:hover:bg-gray-700"
      when :error
        "bg-red-50 focus:ring-red-400 hover:bg-red-200 dark:bg-gray-800 dark:hover:bg-gray-700"
      when :warning
        "bg-yellow-50 focus:ring-yellow-400 hover:bg-yellow-200 dark:bg-gray-800 dark:hover:bg-gray-700"
      when :success
        "bg-green-50 focus:ring-green-400 hover:bg-green-200 dark:bg-gray-800 dark:hover:bg-gray-700"
      end
    end
  end
end
