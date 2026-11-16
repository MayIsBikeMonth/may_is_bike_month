# frozen_string_literal: true

module UI
  module DefinitionList
    module Container
      class Component < ApplicationComponent
        # term: placement of each row's term (dt) relative to its definition (dd).
        # The non-default terms style the child Row divs/dt/dd via descendant
        # selectors (which out-specify the Row's own utility classes), so Rows
        # need no term awareness.
        #
        # :left_align  — term left, definition right-aligned (supports multi_columns)
        # :right_align — term right-aligned in a fixed column, definition beside it
        # :below       — definition below the term, three columns desktop / two mobile
        TERMS = %i[left_align right_align below].freeze

        # Summary panel (single column): keeps the Row's label-left / value-right
        # layout (justify-between), just resizing to consumer_desktop.html — label
        # 13px, value 13.5px semibold
        PANEL_CLASSES = "flex flex-col gap-2.5 break-words " \
          "[&>div]:pt-0 " \
          "[&>div>dt]:text-[13px] " \
          "[&>div>dd]:text-[13.5px] [&>div>dd]:font-semibold"

        # Spec-sheet lists (multi column): right-aligned label column beside
        # normal-weight values, two columns on desktop
        SPECS_CLASSES = "grid grid-cols-1 gap-x-[22px] gap-y-[13px] break-words sm:grid-cols-2 " \
          "[&>div]:pt-0 [&>div]:gap-x-3 " \
          "[&>div>dt]:w-28 [&>div>dt]:flex-none [&>div>dt]:text-right [&>div>dt]:text-[13px] " \
          "[&>div>dd]:flex-1 [&>div>dd]:text-left [&>div>dd]:text-[13.5px]"

        BELOW_CLASSES = "grid grid-cols-2 gap-x-5 gap-y-[18px] break-words lg:grid-cols-3 " \
          "[&>div]:block [&>div]:pt-0 " \
          "[&>div>dt]:mb-[3px] [&>div>dt]:text-[11.5px] " \
          "[&>div>dd]:text-left [&>div>dd]:text-[14px] [&>div>dd]:font-medium"

        def initialize(term: :left_align, multi_columns: false)
          raise ArgumentError, "term must be one of #{TERMS.inspect}, got #{term.inspect}" unless TERMS.include?(term)

          @term = term
          @multi_columns = multi_columns
        end

        private

        def dl_classes
          return BELOW_CLASSES if @term == :below

          # A right_align list is a spec sheet when multi-column, otherwise a
          # single-column summary panel (label left, value right)
          @multi_columns ? SPECS_CLASSES : PANEL_CLASSES
        end
      end
    end
  end
end
