# frozen_string_literal: true

module ComponentStructs
  # The hashes UI::Tabs (a tab) and UI::ButtonGroup (an entry) take, so a caller can't
  # spell a shape a way the component doesn't read. **attributes carries a caller's own keys.
  module Shapes
    extend Functionable

    # count: renders beside the label, classes: adds to the tab's own
    def tab(label, href, active: false, count: nil, classes: nil, **attributes)
      {label:, href:, active:, count:, classes:, **attributes}
    end

    # An entry without an href renders a <button> rather than a link, so href: is where a
    # chip driven by a Stimulus action differs from one that navigates
    def entry(label, href: nil, active: false, disabled: false, **attributes)
      {label:, href:, active:, disabled:, **attributes}
    end
  end
end
