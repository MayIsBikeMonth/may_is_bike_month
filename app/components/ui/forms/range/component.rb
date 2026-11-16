# frozen_string_literal: true

module UI
  module Forms
    module Range
      # A slider under its label, which shows the value as it moves (ui--forms--range), and beneath it what its ends mean,
      # min_label's and max_label's.
      #
      # html_options go on the input, as with UI::Forms::Input - a class there joins the component's own, and a
      # data action runs beside the component's.
      class Component < ApplicationComponent
        INPUT_CLASSES = "w-full accent-[#715eb2]"

        def initialize(name:, label:, value:, max:, min: 0, step: 1, min_label: nil, max_label: nil, html_options: {})
          @name = name
          @label = label
          @value = value
          @min = min
          @max = max
          @step = step
          @min_label = min_label
          @max_label = max_label
          @id = html_options[:id] || name
          data = html_options[:data] || {}
          @html_options = html_options.except(:id, :class, :data).merge(
            class: [INPUT_CLASSES, html_options[:class]].compact.join(" "),
            data: data.merge(action: ["input->ui--forms--range#update", data[:action]].compact.join(" "))
          )
        end

        def call
          tag.div(data: {controller: "ui--forms--range"}) do
            tag.label(class: "flex justify-between text-sm", for: @id) do
              tag.span(@label) +
                tag.output(@value, for: @id, class: "text-gray-500 tabular-nums dark:text-gray-400",
                  data: {"ui--forms--range-target": "output"})
            end + tag.input(type: "range", id: @id, name: @name, min: @min, max: @max, step: @step, value: @value, **@html_options) + ends
          end
        end

        private

        def ends
          return if @min_label.blank? && @max_label.blank?

          tag.div(tag.span(@min_label) + tag.span(@max_label, class: "text-right"),
            class: "-mt-2 flex justify-between gap-2 text-xs text-gray-500 dark:text-gray-400")
        end
      end
    end
  end
end
