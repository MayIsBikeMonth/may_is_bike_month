# frozen_string_literal: true

# Helpers shared across :js system specs
module IntegrationSpecHelpers
  SKIPPABLE_AXE_RULES = %w[aria-allowed-role color-contrast empty-table-header heading-order html-has-lang
    landmark-one-main landmark-unique page-has-heading-one region].freeze

  def expect_axe_clean(*extra_skipped_rules)
    expect(page).to be_axe_clean.skipping(*SKIPPABLE_AXE_RULES, *extra_skipped_rules.map(&:to_s))
  end

  # Stimulus lazy loads controller modules, so a rendered page can have none of them
  # connected yet. `every` is vacuously true on a document that has parsed no
  # [data-controller] at all, so name the one being waited for and the wait covers it
  # arriving as well as connecting
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

  # Flash messages are fixed position, so an undismissed one intercepts clicks on whatever
  # it overlays. A click landing before ui--alert connects is swallowed, so click again
  # for the whole of `wait`
  def dismiss_flash_messages(wait: 10)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + wait
    loop do
      all("#flash-messages [aria-label='Close']", minimum: 1).each do |close|
        close.click
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        nil
      end
      break if page.has_no_css?("#flash-messages [role='alert']", wait: 1)
      break if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    end
    expect(page).to have_no_css("#flash-messages [role='alert']", wait: 1)
  end

  def wait_for(timeout: 5)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      raise "waited #{timeout}s for the block to be true" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      sleep 0.05
    end
  end
end

RSpec.configure do |config|
  config.include IntegrationSpecHelpers, type: :system
end
