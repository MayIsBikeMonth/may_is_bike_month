# frozen_string_literal: true

# Helpers shared across :js system specs - the steps more than one of them walks, and the
# browser behavior Capybara doesn't abstract across drivers, which is implemented for the
# Playwright driver via its raw page (see spec/support/capybara.rb).
module IntegrationSpecHelpers
  # Turn on touch emulation, which is what makes `(pointer: coarse)` match, so
  # touch-only styles render (Playwright's emulate_media doesn't cover pointer).
  # The session is left attached -- the browser context is recreated between examples,
  # which is teardown enough.
  def emulate_touch_device
    page.driver.with_playwright_page do |playwright_page|
      session = playwright_page.context.new_cdp_session(playwright_page)
      session.send_message("Emulation.setTouchEmulationEnabled", params: {enabled: true, maxTouchPoints: 1})
    end
  end

  # Resize for this example only -- the browser context is recreated between
  # examples, so the configured viewport comes back on its own.
  def resize_window(width:, height:)
    page.driver.with_playwright_page { |playwright_page| playwright_page.set_viewport_size(width:, height:) }
  end

  # The colors an element paints right now, for comparing one state against another.
  # A node script binds the element to `this` on this driver -- an (el) => arrow returns
  # nil, which would compare equal to itself and assert nothing.
  #
  # No box-shadow: pressing an element focuses it, so its focus ring would tell every
  # pressed state apart from its hover no matter what the colors do.
  def computed_colors(element)
    element.evaluate_script("[getComputedStyle(this).backgroundColor, getComputedStyle(this).color, getComputedStyle(this).borderTopColor, getComputedStyle(this).textDecorationLine, getComputedStyle(this).fontWeight]")
  end

  # The ring an element wears right now — box-shadow is how Tailwind draws one.
  def computed_ring(element)
    element.evaluate_script("getComputedStyle(this).boxShadow")
  end

  # Everything a state can change about how an element looks, for telling states apart
  def state_of(element)
    [computed_colors(element), computed_ring(element)]
  end

  SETTLE_JS = <<~JS
    Promise.race([
      new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)))
        .then(() => Promise.all(this.getAnimations().map((animation) => animation.finished.catch(() => {})))),
      new Promise((resolve) => setTimeout(resolve, arguments[0]))
    ])
  JS

  # Block until an element's transitions and animations have finished, for anything that
  # measures what a state change left behind -- a measurement taken the instant the state
  # changes reads the value it's transitioning *from*, which makes an assertion that
  # nothing changed pass no matter what the CSS says. Two frames for the new style to
  # apply and create the transitions, so a state that transitions nothing costs only those.
  #
  # Prefer this to a fixed sleep, which has to be as long as the slowest case and is still
  # wrong when something outruns it. `cap` is the ceiling rather than the wait: `finished`
  # rejects on a cancelled transition and never settles for an infinite animation, and the
  # cap is what stops either hanging the example.
  def settle_animations(element, cap: 400)
    element.evaluate_script(SETTLE_JS, cap)
  end

  # Point at an element and hold the mouse down, yielding at each state so the caller
  # can measure. Capybara can hover but has no press-and-hold, and :active is only
  # reachable by actually holding the button down, the way a rider does.
  #
  # Each yield is outside the driver block on purpose: Capybara's evaluate_script
  # returns nil while the raw page is checked out, which silently turns a caller's
  # measurement into nil == nil. The mouse holds its state between blocks.
  def hover_then_press(element, cap: 400)
    box = element.native.bounding_box
    x, y = box["x"] + box["width"] / 2, box["y"] + box["height"] / 2
    move_mouse(element, cap:) { |mouse| mouse.move(x, y) }
    yield :hover
    move_mouse(element, cap:, &:down)
    yield :press
    move_mouse(element, cap:) { |mouse| mouse.up.tap { mouse.move(0, 0) } }
  end

  def drag_select(element, past:)
    box = element.native.bounding_box
    middle = box["y"] + box["height"] / 2
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.mouse.move(box["x"] + 2, middle)
      playwright_page.mouse.down
      playwright_page.mouse.move(box["x"] + box["width"] + past, middle, steps: 12)
      playwright_page.mouse.up
    end
  end

  # Type into a field with real keystrokes. Capybara's `set`/`fill_in` go through
  # Playwright's fill, which dispatches only an `input` event; JS that opens on
  # keydown (e.g. hotwire_combobox's async dropdown) needs real key events. A combobox
  # typed into before its controller connects never searches, so that waits first.
  # has_ancestor? because matches_css? can't ask this: it resolves against the field's parent,
  # and Playwright scopes a selector to its root, so an ancestor above that never matches.
  def type_into(locator, text)
    field = locator.is_a?(Capybara::Node::Element) ? locator : find(locator)
    wait_for_stimulus("hw-combobox") if field.has_ancestor?("[data-controller~='hw-combobox']", wait: 0)
    field.set("")
    field.send_keys(text)
    field
  end

  # Stimulus lazy loads controller modules, so a rendered page can have none of them
  # connected yet -- a combobox filters no options, a restored draft reaches no listener.
  # `every` is vacuously true on a document that has parsed no [data-controller] at all,
  # so name the one being waited for and the wait covers it arriving as well as connecting
  def wait_for_stimulus(identifier = nil, timeout: Capybara.default_max_wait_time)
    wait_for(timeout:) do
      page.evaluate_script(<<~JS)
        [...document.querySelectorAll('[data-controller]')].every((element) =>
          element.dataset.controller.split(' ').filter(Boolean).every((identifier) =>
            window.Stimulus?.getControllerForElementAndIdentifier(element, identifier)))
      JS
    end
    return if identifier.blank?

    wait_for(timeout:) do
      page.evaluate_script(<<~JS)
        (() => {
          const element = document.querySelector('[data-controller~="#{identifier}"]')
          return !!(element && window.Stimulus?.getControllerForElementAndIdentifier(element, "#{identifier}"))
        })()
      JS
    end
  end

  # capybara-playwright wraps click/find so a mid-action "Element is not attached
  # to the DOM" (Turbo re-rendering the field) becomes a StaleReferenceError that
  # Capybara auto-retries -- but its `set` path (fill_in) only rescues timeouts,
  # so the raw Playwright::Error escapes. Re-find and re-fill on detach, which is
  # what Capybara does for the wrapped actions.
  def fill_in(*args, **options, &block)
    retry_on_detach { super }
  end

  # Takes the trigger (a page with two of them opens the same modal from either), which names
  # the dialog. The trigger's own command/commandfor is what opens it, so one click is enough
  # and a page that lost them fails here rather than opening once Stimulus catches up.
  def open_modal(trigger)
    element = trigger.is_a?(Capybara::Node::Element) ? trigger : find(trigger)
    retry_on_detach { element.click }
    expect(page).to have_css("##{element["commandfor"]}[open]")
  end

  # A dialog holding the page behind it pins the body - with overflow everywhere
  # except iOS, where only position sticks. Pass to have_css/have_no_css, so the
  # unlock gets Capybara's wait: closing a dialog fires `close` a task later.
  def scroll_locked_body
    "body[style*='overflow: hidden'], body[style*='position: fixed']"
  end

  # hotwire_combobox's scroll lock picks its mechanism at import from
  # navigator.platform, and only its iOS branch reaches document. Call before `visit`.
  def emulate_ios_platform
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.add_init_script(script: "Object.defineProperty(navigator, 'platform', {get: () => 'iPhone'})")
    end
  end

  # iOS locks the page by preventing document's touchmove, which leaves no mark on
  # the body for scroll_locked_body to catch - and outlives the body it was taken for
  def touch_scroll_blocked?
    page.evaluate_script(<<~JS)
      (() => {
        const event = new TouchEvent('touchmove', {bubbles: true, cancelable: true, touches: [], targetTouches: [], changedTouches: []})
        document.body.dispatchEvent(event)
        return event.defaultPrevented
      })()
    JS
  end

  # Block until something no Capybara matcher can see is true - a route handler's record
  # of a request it answered, say
  def wait_for(timeout: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      raise "waited #{timeout}s for the block to be true" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      sleep 0.05
    end
  end

  # Flash messages are fixed position, so an undismissed one intercepts clicks on
  # whatever it overlays. ui--alert wires the close button in `connect` and
  # application.js lazy loads controllers, so a click landing before that module
  # arrives is swallowed. Click again, the way a rider whose click did nothing
  # would, for the whole of `wait` - a click is the only thing that dismisses an
  # alert, so time spent waiting without clicking can never resolve one.
  def dismiss_flash_messages(wait: 10)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + wait
    loop do
      all("#flash-messages [aria-label='Close']", minimum: 1).each { |close| retry_on_detach { close.click } }
      break if page.has_no_css?("#flash-messages [role='alert']", wait: 1)
      break if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    end
    expect(page).to have_no_css("#flash-messages [role='alert']", wait: 1)
  end

  private

  # The settle is outside the driver block because evaluate_script returns nil while
  # the raw page is checked out -- the same trap the yields in hover_then_press avoid.
  def move_mouse(element, cap:)
    page.driver.with_playwright_page { |playwright_page| yield playwright_page.mouse }
    settle_animations(element, cap:)
  end

  # Retry a Playwright action when the node detaches mid-action -- the raw
  # Playwright::Error that Capybara's own retry doesn't rescue on this driver.
  def retry_on_detach(attempts: 3)
    tries = 0
    begin
      yield
    rescue Playwright::Error => e
      raise unless e.message.include?("not attached to the DOM") && (tries += 1) <= attempts
      sleep 0.1
      retry
    end
  end
end

RSpec.configure do |config|
  config.include IntegrationSpecHelpers, type: :system
end
