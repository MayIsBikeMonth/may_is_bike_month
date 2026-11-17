# frozen_string_literal: true

module UI
  module Forms
    module Input
      class Component < ApplicationComponent
        # Every kind takes (attribute, html_options) — a select doesn't, so it's
        # UI::Forms::Select instead. No email either: an email field is UI::Forms::Email,
        # which asks for the type itself so that every one of them checks for a typo.
        KINDS = %i[text_field text_area number_field telephone_field datetime_local_field].freeze

        PREFIX_CLASS = "flex items-center whitespace-nowrap rounded-l-sm border border-r-0 " \
          "border-gray-200 bg-gray-100 px-2.5 text-gray-500 " \
          "dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400"

        # UI::Forms::Group forwards a kind here, so it validates through this too
        def self.validate_kind!(kind)
          return kind.to_sym if KINDS.include?(kind&.to_sym)

          raise ArgumentError, "unknown kind #{kind.inspect}, expected one of: #{KINDS.join(", ")}"
        end

        def initialize(form_builder:, attribute:, kind: :text_field, required: false, prefix: nil, html_options: {})
          @form_builder = form_builder
          @attribute = attribute
          @kind = self.class.validate_kind!(kind)
          @prefix = prefix.presence
          @html_options = html_options.merge(
            {class: ["twinput", ("rounded-l-none" if @prefix), html_options[:class]].compact.join(" ")},
            (required ? {required: true} : {})
          )
        end

        def call
          return field unless @prefix

          tag.div(safe_join([tag.span(@prefix, class: PREFIX_CLASS), field]), class: "flex")
        end

        private

        def field
          @form_builder.send(@kind, @attribute, @html_options)
        end
      end
    end
  end
end
