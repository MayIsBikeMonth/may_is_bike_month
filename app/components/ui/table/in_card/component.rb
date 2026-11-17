# frozen_string_literal: true

module UI
  module Table
    module InCard
      # A UI::Table::Base that fills a card edge to edge, its first column frozen against the
      # horizontal scroll. Columns are declared as on UI::Table::Base, and their blocks run there.
      # Given column_settings, it renders its own full-bleed card, under them
      class Component < ApplicationComponent
        renders_one :description
        renders_one :actions

        # Descendant selectors, so they outrank the cell classes UI::Table::Base gives every column
        TABLE_CLASSES = [
          "[&_th]:whitespace-nowrap [&_th]:border-b [&_th]:border-gray-100 [&_th]:bg-gray-50",
          "[&_th]:px-4 [&_th]:py-2.5 [&_th]:text-2xs [&_th]:font-normal [&_th]:text-gray-400 [&_th]:uppercase",
          # twlink's blue gives way to the header's gray, underlined like twlink-underlined
          "[&_th_a]:text-inherit [&_th_a]:underline [&_th_a:hover]:decoration-2 [&_th_a[data-active]]:decoration-2",
          "[&_td]:bg-white [&_td]:px-4 [&_td]:py-2.5 [&_td]:text-sm [&_tr:hover_td]:bg-yellow-50",
          # Whatever follows the table draws the line under it
          "[&_tbody_tr:last-child_td]:border-b-0",
          "dark:[&_th]:border-gray-700 dark:[&_th]:bg-gray-800 dark:[&_td]:bg-gray-900",
          # Opaque, or the cells scrolling under the frozen column show through it
          "dark:[&_tr:hover_td]:bg-[color-mix(in_oklab,var(--color-yellow-950)_40%,var(--color-gray-900))]"
        ].join(" ").freeze

        # The page's background in dark as well as light, so only the headers and settings stand out.
        # On an element marked data-table-bleed, which is what ui--table-overflow flags
        CARD_CLASSES = "rounded-xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900 " \
          "table-bleed:rounded-none table-bleed:border-0"

        # Shadowed once the ui--table-overflow controller flags there's any to scroll
        FROZEN_COLUMN_CLASSES = "w-px sticky left-0 z-1 border-r border-r-gray-100 " \
          "group-data-overflowing/table-in-card:shadow-[2px_0_6px_rgba(26,26,31,0.04)] dark:border-r-gray-700"

        # [&>div] is UI::Table::Base's scroller, whose bottom spacing would part the table from what
        # follows it. The after: box mirrors the frozen column's divider and shadow on the right
        # edge while there's more to scroll, except in a full-bleed row that runs off the page
        WRAPPER_CLASSES = "group/table-in-card relative [&>div]:mb-0 [&>div]:pb-0 data-overflowing:after:absolute " \
          "data-overflowing:after:inset-y-0 data-overflowing:after:left-[calc(100%-1px)] data-overflowing:after:z-2 " \
          "data-overflowing:after:w-4 data-overflowing:after:border-l data-overflowing:after:border-gray-100 " \
          "data-overflowing:after:shadow-[-2px_0_6px_rgba(26,26,31,0.04)] dark:data-overflowing:after:border-gray-700 " \
          "data-scrolled-end:after:hidden table-bleed:after:hidden"

        # column_settings: UI::Table::ColumnSettings' columns, defaults and narrow_hidden, plus its storage_key.
        # form: form_with's options, making the card a form whose actions apply to - and show once there are -
        # rows checked in selection_column. data: the outermost element's, its controllers and actions joining these.
        # The rest go to UI::Table::Base
        def initialize(column_settings: nil, form: nil, data: {}, **table_options)
          @column_settings = column_settings
          @form = form
          @data = data
          @table_options = table_options
          @columns = []
        end

        # hideable: the column's cell_name, labeled by column_settings unless given a label
        def column(hideable: nil, **options, &block)
          if hideable
            options = {label: @column_settings&.dig(:columns, hideable), **options, classes: token_list("hideableColumn", hideable, options[:classes])}
          end
          @columns << [options, block]
          nil
        end

        # The form's checkboxes, named param[id] for the row's record - or the first of its array, which
        # disabled is called with. The block renders beside each
        def selection_column(param:, disabled: nil, &block)
          column(label: toggle_all_button) do |row|
            record = row.is_a?(Array) ? row.first : row
            checkbox = check_box_tag("#{param}[#{record.id}]", record.id, false, disabled: disabled&.call(record),
              aria: {label: "Select #{record.model_name.human.downcase} #{record.id}"}, data: {"table-multi-checkbox-target" => "checkbox"})
            next checkbox unless block

            tag.div(safe_join([checkbox, capture { instance_exec(row, &block) }]), class: "flex items-center gap-3")
          end
        end

        def before_render
          content
        end

        private

        def toggle_all_button
          render(UI::Button::Component.new(text: check_mark, color: :link, title: "Toggle all checked",
            aria: {label: "Toggle all checked"}, data: {action: "click->table-multi-checkbox#toggleAll"}))
        end

        def wrapper_data
          data = @column_settings ? {} : @data
          data.merge(controller: token_list("ui--table-overflow", data[:controller]))
        end

        def card(&)
          classes = "col-span-full min-w-0 #{CARD_CLASSES}"
          return form_with(**@form, class: classes, data: card_data, &) if @form

          tag.div(class: classes, data: card_data, &)
        end

        def card_data
          data = UI::Table::ColumnSettings::Component.data_attributes(storage_key: @column_settings[:storage_key], orderable: true,
            controllers: token_list(("table-multi-checkbox" if @form), @data[:controller]).presence)
          selection = "input->table-multi-checkbox#selectRow submit->table-multi-checkbox#confirmDiscard" if @form
          @data.merge(data, table_bleed: false, action: token_list(data[:action], selection, @data[:action]))
        end

        def column_options(options, index)
          options.merge(classes: [(FROZEN_COLUMN_CLASSES if index.zero?), options[:classes]].compact.join(" "))
        end
      end
    end
  end
end
