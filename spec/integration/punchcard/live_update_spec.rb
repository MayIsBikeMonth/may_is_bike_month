# frozen_string_literal: true

require "rails_helper"

# Exercises the `punch` Stimulus controller, which preserves user selection
# across turbo morphs. These tests synthesize the turbo morph lifecycle by
# dispatching `turbo:before-morph-element` / `turbo:morph-element` on the
# wrapper and mutating the DOM in between, rather than relying on
# ActionCable broadcasts (the test adapter doesn't round-trip to the
# browser).
#
# Fixture setup isolates the three capture paths:
# - Alice has two activities (days 5 and 10), so clicking her user button is
#   meaningfully different from clicking either punch individually.
# - Bob is in the competition but starts with no activity — his row exists
#   but has zero punch buttons. A morph-added punch for Bob can therefore
#   only become pressed via day-capture or all-capture, never via URL
#   reapply.
RSpec.describe "Punchcard live update", :js, type: :system do
  around { |ex| travel_to(Time.parse("2026-05-20T12:00:00Z")) { ex.run } }

  let!(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2026-05-01"), current: true) }
  let(:alice) { FactoryBot.create(:user, display_name: "Alice") }
  let(:bob) { FactoryBot.create(:user, display_name: "Bob") }
  let!(:alice_cu) { FactoryBot.create(:competition_user, competition:, user: alice) }
  let!(:bob_cu) { FactoryBot.create(:competition_user, competition:, user: bob) }

  let!(:alice_day5) do
    FactoryBot.create(:competition_activity, competition_user: alice_cu,
      distance_meters: 16_093, start_at: Time.parse("2026-05-05T15:00:00Z"))
  end
  let!(:alice_day10) do
    FactoryBot.create(:competition_activity, competition_user: alice_cu,
      distance_meters: 16_093, start_at: Time.parse("2026-05-10T15:00:00Z"))
  end

  let(:wrapper_id) { ActionView::RecordIdentifier.dom_id(competition, :punchcard_wrapper) }

  # Synthesize a turbo morph: optionally fire the capture phase, append a new
  # punch button to the target user's row, then fire the morph-element event.
  def morph_in_punch(user_slug:, date_string:, before_morph: true)
    page.execute_script(<<~JS, wrapper_id, user_slug, date_string, before_morph)
      const [wrapperId, userSlug, dateString, beforeMorph] = arguments
      const wrapper = document.getElementById(wrapperId)
      if (beforeMorph) {
        wrapper.dispatchEvent(new CustomEvent('turbo:before-morph-element', { bubbles: true }))
      }
      const row = wrapper.querySelectorAll('.punchcard-week')[
        Array.from(wrapper.querySelectorAll('[data-punch-target="userButton"]'))
          .findIndex(btn => btn.dataset.userSlug === userSlug)
      ]
      const btn = document.createElement('button')
      btn.type = 'button'
      btn.className = 'punchcard-cell'
      btn.setAttribute('aria-pressed', 'false')
      btn.dataset.action = 'click->punch#toggle'
      btn.dataset.punchTarget = 'punch'
      btn.dataset.punchId = `${userSlug}-${dateString}`
      btn.dataset.date = dateString
      btn.dataset.userSlug = userSlug
      btn.dataset.l = '1'
      row.appendChild(btn)
      wrapper.dispatchEvent(new CustomEvent('turbo:morph-element', { bubbles: true }))
    JS
    # Wait for the microtask-debounced rebuild to run.
    page.evaluate_script("new Promise(r => queueMicrotask(() => queueMicrotask(r)))")
  end

  def punch_selector(user_slug:, date_string:)
    %([data-punch-target="punch"][data-user-slug="#{user_slug}"][data-date="#{date_string}"])
  end

  def pressed?(node)
    node["aria-pressed"] == "true"
  end

  def show_all_button
    find("button", text: "Show all activities")
  end

  before do
    visit root_path
    expect(page).to have_css('[data-controller="punch"] [data-punch-target="punch"]')
  end

  describe "'Show all activities' button active state" do
    it "is aria-pressed when every punch is active and clears when any is deselected" do
      expect(show_all_button["aria-pressed"]).to eq "false"

      click_button("Show all activities")

      expect(show_all_button["aria-pressed"]).to eq "true"

      find(punch_selector(user_slug: alice.slug, date_string: "2026-05-05")).click

      expect(show_all_button["aria-pressed"]).to eq "false"
    end
  end

  describe "group intent preserved across morph" do
    context "when a user row is fully active" do
      # Alice has days 5 and 10. Clicking her button activates both. A morph
      # then adds day 15 — neither the URL (no day 15 entry) nor day-capture
      # (no day is fully active) would press it; only user-capture can.
      it "activates newly-rendered punches for that user" do
        click_button("Alice")
        expect(pressed?(find(punch_selector(user_slug: alice.slug, date_string: "2026-05-05")))).to be true
        expect(pressed?(find(punch_selector(user_slug: alice.slug, date_string: "2026-05-10")))).to be true

        morph_in_punch(user_slug: alice.slug, date_string: "2026-05-15")

        expect(pressed?(find(punch_selector(user_slug: alice.slug, date_string: "2026-05-15")))).to be true
      end
    end

    context "when a specific day ridge bar is fully active" do
      # Click day 5 ridge bar → only alice:5 is pressed. Alice's row is NOT
      # fully active (day 10 is unpressed), so she won't be captured as an
      # active user. Morph adds bob:day5 — only day-capture can press it.
      it "activates newly-rendered punches for that date" do
        find(%([data-punch-target="ridgeBar"][data-date="2026-05-05"])).click
        expect(pressed?(find(punch_selector(user_slug: alice.slug, date_string: "2026-05-05")))).to be true
        expect(pressed?(find(punch_selector(user_slug: alice.slug, date_string: "2026-05-10")))).to be false

        morph_in_punch(user_slug: bob.slug, date_string: "2026-05-05")

        expect(pressed?(find(punch_selector(user_slug: bob.slug, date_string: "2026-05-05")))).to be true
      end
    end

    context "when all activities are shown" do
      # Click "Show all" → both alice punches pressed, everything active.
      # Morph adds bob:day5 — bob has no prior punches so he can't be in
      # activeUsers, but allActive covers him.
      it "activates newly-rendered punches and keeps the button aria-pressed" do
        click_button("Show all activities")

        morph_in_punch(user_slug: bob.slug, date_string: "2026-05-05")

        expect(pressed?(find(punch_selector(user_slug: bob.slug, date_string: "2026-05-05")))).to be true
        expect(show_all_button["aria-pressed"]).to eq "true"
      end
    end
  end

  describe "punches added by morph are indexed immediately" do
    # Regression: the controller previously read `this.punchTargets` from
    # Stimulus inside the synchronous morph handler, which was stale because
    # Stimulus updates targets via MutationObserver on the next microtask.
    # New punches weren't in `punchesByDate`, so clicking the day's ridge bar
    # was a no-op.
    it "lets the ridge bar activate a punch that arrived during the morph" do
      morph_in_punch(user_slug: alice.slug, date_string: "2026-05-15", before_morph: false)

      find(%([data-punch-target="ridgeBar"][data-date="2026-05-15"])).click

      expect(pressed?(find(punch_selector(user_slug: alice.slug, date_string: "2026-05-15")))).to be true
      expect(find(%([data-punch-target="ridgeBar"][data-date="2026-05-15"]))["aria-pressed"]).to eq "true"
    end
  end

  describe "selecting a day that has no activity yet" do
    # Day 3 has no activity from anyone; its ridge bar renders as a button
    # (past/today) but previously did nothing on click because there were
    # no punches to toggle.
    let(:day3_ridge) { find(%([data-punch-target="ridgeBar"][data-date="2026-05-03"])) }

    it "toggles aria-pressed, persists to ?days=, survives reload, and picks up morphed-in punches" do
      expect(day3_ridge["aria-pressed"]).to eq "false"

      day3_ridge.click
      expect(day3_ridge["aria-pressed"]).to eq "true"
      expect(page.current_url).to include "days=3"

      # Second click toggles off.
      day3_ridge.click
      expect(day3_ridge["aria-pressed"]).to eq "false"
      expect(page.current_url).not_to include "days=3"

      # Re-select, then reload: URL persistence restores the selection.
      day3_ridge.click
      visit page.current_url
      reloaded_ridge = find(%([data-punch-target="ridgeBar"][data-date="2026-05-03"]))
      expect(reloaded_ridge["aria-pressed"]).to eq "true"

      # A subsequent morph brings in a punch for that day — it arrives pressed
      # because day 3 is captured as active.
      morph_in_punch(user_slug: alice.slug, date_string: "2026-05-03")
      expect(pressed?(find(punch_selector(user_slug: alice.slug, date_string: "2026-05-03")))).to be true
      expect(find(%([data-punch-target="ridgeBar"][data-date="2026-05-03"]))["aria-pressed"]).to eq "true"
    end
  end

  describe "localizeTime spans morphed in by ActionCable" do
    # Regression: turbo stream broadcasts use morph and fire
    # `turbo:morph-element` (not `turbo:morph`). New `.localizeTime` spans
    # (e.g. the footer's "updated" time) must still get localized.
    it "localizes them on turbo:morph-element" do
      page.execute_script(<<~JS, wrapper_id)
        const wrapper = document.getElementById(arguments[0])
        const span = document.createElement('span')
        span.className = 'localizeTime'
        span.textContent = '2026-05-20T11:00:00+0000'
        wrapper.appendChild(span)
        wrapper.dispatchEvent(new CustomEvent('turbo:morph-element', { bubbles: true }))
      JS

      expect(page).to have_css("##{wrapper_id} > span.localizedTime", wait: 2)
    end
  end
end
