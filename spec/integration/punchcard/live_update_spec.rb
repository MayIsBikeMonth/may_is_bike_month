# frozen_string_literal: true

require "rails_helper"

# Walks the punchcard's full client-side state machine in one example:
# user/day/all-active intent capture across a real ActionCable morph,
# DOM indexing of newly-arrived punches, ?days= vs ?selected= URL
# semantics, URL persistence across reload, and footer time
# localization after a broadcast.
#
# Morphs are produced by real ActionCable broadcasts — the `:test` cable
# adapter inherits from `:async`, so broadcasts in-process do round-trip
# to the browser. `click_button("Hide all activities")` is the reset
# between phases (it clears every press AND in-memory selectedDays).
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

  # Add an activity for the given user on the given date, then broadcast a
  # punchcard refresh. The test cable adapter delivers in-process to the
  # turbo_stream_from subscription, so the browser receives a morph and
  # renders the new punch.
  def morph_in_punch(user:, date_string:)
    competition_user = CompetitionUser.find_by!(user:, competition:)
    FactoryBot.create(:competition_activity, competition_user:,
      distance_meters: 16_093, start_at: Time.parse("#{date_string}T15:00:00Z"))
    Leaderboard::PunchcardWrapper::Component.broadcast_refresh_current!
    expect(page).to have_css(punch_selector(user_slug: user.slug, date_string:), wait: 5)
  end

  def punch_selector(user_slug:, date_string:)
    %([data-punch-target="punch"][data-user-slug="#{user_slug}"][data-date="#{date_string}"])
  end

  def punch_for(user, date_string)
    find(punch_selector(user_slug: user.slug, date_string:))
  end

  def ridge_for(date_string)
    find(%([data-punch-target="ridgeBar"][data-date="#{date_string}"]))
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

  it "captures intents, indexes morphed punches, persists URL state, and localizes broadcast footers" do
    # ----- Show-all button reflects aria-pressed across toggles ---------
    expect(show_all_button["aria-pressed"]).to eq "false"

    click_button("Show all activities")
    expect(show_all_button["aria-pressed"]).to eq "true"

    punch_for(alice, "2026-05-05").click
    expect(show_all_button["aria-pressed"]).to eq "false"

    click_button("Hide all activities")

    # ----- User-row capture: Alice's row stays full across morph -------
    # Clicking Alice presses her two punches. Morph adds alice:15; the
    # URL has no day 15 entry and day 15 isn't fully active, so only
    # user-capture can press the new punch.
    click_button("Alice")
    expect(pressed?(punch_for(alice, "2026-05-05"))).to be true
    expect(pressed?(punch_for(alice, "2026-05-10"))).to be true

    morph_in_punch(user: alice, date_string: "2026-05-15")
    expect(pressed?(punch_for(alice, "2026-05-15"))).to be true

    click_button("Hide all activities")

    # ----- Day-ridge capture: day 5 stays full across morph ------------
    # Clicking the day-5 ridge presses just alice:5 (her row is partial,
    # so user-capture won't fire). Morph adds bob:5 — only day-capture
    # can press it.
    ridge_for("2026-05-05").click
    expect(pressed?(punch_for(alice, "2026-05-05"))).to be true
    expect(pressed?(punch_for(alice, "2026-05-10"))).to be false

    morph_in_punch(user: bob, date_string: "2026-05-05")
    expect(pressed?(punch_for(bob, "2026-05-05"))).to be true

    click_button("Hide all activities")

    # ----- All-active capture: Show-all stays pressed across morph -----
    # bob has no prior punches before phase D, so user-capture can't
    # cover bob:7; allActive does.
    click_button("Show all activities")
    expect(show_all_button["aria-pressed"]).to eq "true"

    morph_in_punch(user: bob, date_string: "2026-05-07")
    expect(pressed?(punch_for(bob, "2026-05-07"))).to be true
    expect(show_all_button["aria-pressed"]).to eq "true"

    click_button("Hide all activities")

    # ----- Indexing regression: morph-added punches are queryable -----
    # The controller previously read `this.punchTargets` from Stimulus
    # inside the synchronous morph handler, which was stale because
    # Stimulus updates targets via MutationObserver on the next
    # microtask. Without prior intent, alice:17 must still be indexed
    # so clicking the day-17 ridge presses it.
    morph_in_punch(user: alice, date_string: "2026-05-17")
    ridge_for("2026-05-17").click
    expect(pressed?(punch_for(alice, "2026-05-17"))).to be true
    expect(ridge_for("2026-05-17")["aria-pressed"]).to eq "true"

    click_button("Hide all activities")

    # ----- Empty-day ridge: toggle, persistence, reload, then morph ---
    # Day 1 has no activity from anyone; its ridge bar is a button but
    # has no punches to toggle. Selection is tracked in selectedDays,
    # serialized to ?days=, and survives reload — at which point a
    # morph-added punch for that day is auto-pressed via day-capture.
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "false"

    ridge_for("2026-05-01").click
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "true"
    expect(page.current_url).to include "days=1"

    ridge_for("2026-05-01").click
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "false"
    expect(page.current_url).not_to include "days=1"

    ridge_for("2026-05-01").click
    visit page.current_url
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "true"

    morph_in_punch(user: alice, date_string: "2026-05-01")
    expect(pressed?(punch_for(alice, "2026-05-01"))).to be true
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "true"

    click_button("Hide all activities")

    # ----- ?days= reflects explicit day-group intent only --------------
    # Day 5 now has two punches (alice:5 from fixtures + bob:5 from the
    # earlier morph), so we can distinguish "ridge-bar click" from
    # "every individual punch clicked" on the same day.
    ridge_for("2026-05-05").click
    expect(page.current_url).to include "days=5"
    expect(page.current_url).not_to include "selected="

    visit page.current_url
    expect(pressed?(punch_for(alice, "2026-05-05"))).to be true
    expect(pressed?(punch_for(bob, "2026-05-05"))).to be true

    # Unpressing any punch on a "selected day" drops the day and the
    # remaining press is written to ?selected=.
    punch_for(alice, "2026-05-05").click
    expect(page.current_url).not_to include "days=5"
    expect(page.current_url).to include "selected=#{bob.slug}%3A5"
    expect(page.current_url).not_to include "#{alice.slug}%3A5"

    click_button("Hide all activities")
    expect(page.current_url).not_to include "days="
    expect(page.current_url).not_to include "selected="

    # Pressing every individual punch on a day never adds to ?days=.
    punch_for(alice, "2026-05-05").click
    punch_for(bob, "2026-05-05").click
    expect(page.current_url).not_to include "days=5"
    expect(page.current_url).to include "#{alice.slug}%3A5"
    expect(page.current_url).to include "#{bob.slug}%3A5"

    click_button("Hide all activities")

    # 'Show all activities' adds every available day to ?days=.
    click_button("Show all activities")
    expected_days = (1..20).to_a.join("%2C")
    expect(page.current_url).to include "days=#{expected_days}"
    expect(page.current_url).not_to include "selected="

    click_button("Hide all activities")

    # ----- Footer 'updated' time gets localized after broadcast --------
    # Regression: turbo stream broadcasts use morph and fire
    # `turbo:morph-element` (not `turbo:morph`), so the `.localizeTime`
    # span rendered into the footer by the morph must still get
    # localized by the time-localizer.
    expect(page).not_to have_css(".localizeTime")
    expect(page).not_to have_css(".localizedTime")

    FactoryBot.create(:strava_request, user: alice, created_at: Time.parse("2026-05-20T11:30:00Z"))
    Leaderboard::PunchcardWrapper::Component.broadcast_refresh_current!

    expect(page).to have_css(".localizedTime", wait: 5)
    expect(page).not_to have_css(".localizeTime")
  end
end
