# frozen_string_literal: true

module Form
  module Group
    class Component < ApplicationComponent
      LABEL_CLASSES = "block mb-1 text-sm font-medium text-gray-700 dark:text-gray-300"

      def initialize(form_builder:, attribute:, kind: :text_field, label_text: nil, html_options: {})
        @form_builder = form_builder
        @attribute = attribute
        @kind = kind
        @label_text = label_text || attribute.to_s.humanize
        @html_options = html_options
      end

      private

      def checkbox? = @kind&.to_sym == :check_box

      def label_classes
        checkbox? ? "ml-2 text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer" : LABEL_CLASSES
      end

      def input_component
        Form::Input::Component.new(form_builder: @form_builder, attribute: @attribute, kind: @kind, html_options: @html_options)
      end
    end
  end
end
