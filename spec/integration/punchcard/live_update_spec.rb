# frozen_string_literal: true

require "rails_helper"

# Walks the punchcard's full client-side state machine in one example,
# state advancing from click to click — never resetting back to a clean
# slate. Each phase's starting state is the previous phase's end state;
# phase order is chosen so the carried state is exactly what the next
# claim wants to demonstrate.
#
# Morphs are produced by real ActionCable broadcasts — the `:test` cable
# adapter inherits from `:async`, so broadcasts in-process do round-trip
# to the browser.
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

  def url_params
    URI.decode_www_form(URI.parse(page.current_url).query || "").to_h
  end

  def url_days
    url_params["days"]&.split(",") || []
  end

  def url_selected
    url_params["selected"] || ""
  end

  before do
    visit root_path
    expect(page).to have_css('[data-controller="punch"] [data-punch-target="punch"]')
  end

  it "captures intents, indexes morphed punches, persists URL state, and localizes broadcast footers" do
    # ----- Empty-day ridge: toggle, ?days= persistence, reload, then morph ----
    # Day 1 has no activity from anyone; its ridge bar is a button with no
    # punches to toggle. Selection lives in selectedDays, serialized to
    # `?days=1`, and survives reload — a morph-added punch on that day is
    # auto-pressed via day-capture.
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "false"

    ridge_for("2026-05-01").click
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "true"
    expect(url_days).to eq ["1"]

    ridge_for("2026-05-01").click
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "false"
    expect(url_days).to be_empty

    ridge_for("2026-05-01").click
    visit page.current_url

    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "true"

    morph_in_punch(user: alice, date_string: "2026-05-01")
    expect(pressed?(punch_for(alice, "2026-05-01"))).to be true
    expect(ridge_for("2026-05-01")["aria-pressed"]).to eq "true"

    # ----- Indexing regression: morph-added punches are queryable -----
    # The controller previously read `this.punchTargets` from Stimulus
    # inside the synchronous morph handler, which was stale because
    # Stimulus updates targets via MutationObserver on the next
    # microtask. Carry-state-wise, day 17 has no prior intent — the new
    # punch must still be indexed so clicking the day-17 ridge presses it.
    morph_in_punch(user: alice, date_string: "2026-05-17")
    ridge_for("2026-05-17").click
    expect(pressed?(punch_for(alice, "2026-05-17"))).to be true

    # ----- Day-ridge capture across morph + ?days= URL semantics -----
    # Click day 5 ridge bar with day 5 not yet in selectedDays. The click
    # adds it (URL gains `days=5`) and presses alice:5. Day 10 — also
    # alice's, but on a different day — stays unpressed: ridge clicks are
    # scoped to their own date.
    ridge_for("2026-05-05").click
    expect(pressed?(punch_for(alice, "2026-05-05"))).to be true
    expect(pressed?(punch_for(alice, "2026-05-10"))).to be false
    expect(url_days).to include "5"

    # Morph adds bob:5 — day 5 is in selectedDays, so the new punch is
    # pressed via day-capture even though bob has no other punches.
    morph_in_punch(user: bob, date_string: "2026-05-05")
    expect(pressed?(punch_for(bob, "2026-05-05"))).to be true

    # ----- Unpressing a punch on a "selected day" drops the day ----------
    # alice:5 unpressed → day 5 no longer fully active → drops from
    # selectedDays; the remaining bob:5 is written individually.
    punch_for(alice, "2026-05-05").click
    expect(url_days).not_to include "5"
    expect(url_selected).to include "#{bob.slug}:5"
    expect(url_selected).not_to include "#{alice.slug}:5"

    # Pressing alice:5 again, individually, never re-adds day 5 to days=.
    punch_for(alice, "2026-05-05").click
    expect(url_days).not_to include "5"
    expect(url_selected).to include "#{alice.slug}:5"
    expect(url_selected).to include "#{bob.slug}:5"

    # ----- User-row capture across morph -----
    # Clicking Alice toggles every alice punch as a group. Some are
    # pressed and some aren't (alice:10 has been unpressed since fixture
    # setup), so the toggle presses all of them. Morph adds alice:15 —
    # alice's row was fully active before the morph, so user-capture
    # presses the new punch.
    click_button("Alice")
    expect(pressed?(punch_for(alice, "2026-05-10"))).to be true

    morph_in_punch(user: alice, date_string: "2026-05-15")
    expect(pressed?(punch_for(alice, "2026-05-15"))).to be true

    # ----- All-active capture + 'Show all activities' → ?days=all -----
    # Show all presses every punch and adds every available day to
    # selectedDays, so the URL collapses to `days=1,2,…,20` with no
    # `selected=`.
    click_button("Show all activities")
    expect(show_all_button["aria-pressed"]).to eq "true"
    expect(url_days).to eq (1..20).map(&:to_s)
    expect(url_selected).to be_empty

    # Bob has no punch on day 7. Morph adds it; allActive captured before
    # the morph presses everything, so bob:7 arrives pressed and Show-all
    # stays aria-pressed.
    morph_in_punch(user: bob, date_string: "2026-05-07")
    expect(pressed?(punch_for(bob, "2026-05-07"))).to be true
    expect(show_all_button["aria-pressed"]).to eq "true"

    # ----- Show-all button reflects aria-pressed across toggles ----
    # Unpressing any punch breaks the all-active state.
    punch_for(alice, "2026-05-05").click
    expect(show_all_button["aria-pressed"]).to eq "false"

    click_button("Show all activities")
    expect(show_all_button["aria-pressed"]).to eq "true"

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
