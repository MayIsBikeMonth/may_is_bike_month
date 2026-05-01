---
name: integration-testing
description: >-
  May is Bike Month integration spec conventions — these are full
  browser specs (`type: :system, :js`) under `spec/integration/`, and
  every example pays a Selenium boot cost. Bias toward fewer, denser
  examples that walk through state via clicks; prefer named-button
  matchers over CSS selectors or `execute_script`. Trigger when writing
  or modifying any spec under `spec/integration/`, or any `*_spec.rb`
  with `:js` or `type: :system`. Read alongside the `rspec-testing`
  skill, which covers the project's general `context`/`let` style.
---

# Integration testing in May is Bike Month

Integration specs live under `spec/integration/` and run as full browser specs (`type: :system, :js`), driven by Capybara/Selenium. They boot a real Chrome session per example, so they are **expensive**. Optimize for fewer, denser examples and high-level Capybara helpers.

The general `context`/`let` style and "what to test" rules are in the [`rspec-testing`](../rspec-testing/SKILL.md) skill — the rules below extend it for the system-spec case.

## One `it` per setup; many assertions per `it`

Unit specs prefer one assertion per example. **Integration specs prefer the opposite**: when several assertions share the same fixture and the same initial `visit`, fold them into one example that walks through state transitions (click → assert → click → assert).

Use `context` only when the *setup* differs — a different `let!`, a different page, a different feature flag. Don't split a single user flow across sibling `it` blocks just because each step has its own assertion.

**Combine even "independent scenarios" if their setup matches.** It is tempting to leave separate `it`s for things that feel like different concerns ("button-state test", "morph-capture test", "URL persistence test", "footer localization test"). Don't. If they share fixtures and the same initial `visit`, fold them all into one example and use a known reset action (`click_button("Hide all activities")`, navigating away, etc.) between phases. A long, sectioned-with-comments example pays one Selenium boot; four short examples pay four. Failure attribution is fine — the failed line number tells you exactly which phase broke.

**Before writing a new `describe`/`context`/`it`, read the existing file.** When adding coverage to a spec, look for a block whose setup already gets you most of the way there and append clicks/assertions to it. Only add a new block when the setup genuinely differs — otherwise you're paying a fresh Selenium boot for something a few extra lines in an existing example would have covered.

### Good

```ruby
it "hides activities by default and toggles via Show/Hide all and per-user buttons" do
  expect(activity_containers.size).to eq 2
  expect(activity_containers).to all(satisfy { |c| !visible?(c) })

  click_button("Show all activities")

  expect(activity_containers).to all(satisfy { |c| visible?(c) })
  expect(find_button("Show all activities")["aria-pressed"]).to eq "true"

  click_button("Hide all activities")

  expect(activity_containers).to all(satisfy { |c| !visible?(c) })

  click_button("Alice")

  expect(visible?(container_for(alice))).to be true
  expect(visible?(container_for(bob))).to be false
end
```

### Bad

```ruby
# Three browser sessions for what's effectively one user flow.
it "shows activities when Show all is clicked" do
  click_button("Show all activities")
  expect(activity_containers).to all(satisfy { |c| visible?(c) })
end

it "hides them when Hide all is clicked" do
  click_button("Show all activities")
  click_button("Hide all activities")
  expect(activity_containers).to all(satisfy { |c| !visible?(c) })
end

it "toggles per-user when a user button is clicked" do
  click_button("Alice")
  expect(visible?(container_for(alice))).to be true
end
```

## Navigate by clicking, not re-visiting

After the initial `visit` in `before`, prefer **clicking** to get to the next state. Re-visiting bypasses the very thing system specs exist to verify (client-side state, JS handlers, history, ARIA wiring).

Re-visit only when you specifically want to verify **URL persistence / reload behavior** — and make that intent explicit (`visit page.current_url` with a comment, or a context named "after reload").

```ruby
# Good — drive the flow with clicks
visit root_path
click_button("Show all activities")
click_link("Alice")

# Good — explicit reload to verify URL persistence
visit page.current_url

# Bad — re-rendering that should have been a click
visit "#{root_path}?show_all=1"
```

## Prefer named matchers over CSS selectors and JS

Capybara's high-level helpers find elements by visible role + text. They are more readable, more accessible (they only see what a real user can interact with), and less brittle than scraping selectors. Reach for low-level tools only when the high-level ones can't express what you need.

Order of preference:

1. **Named-element helpers**: `click_button("Show all activities")`, `click_link("Alice")`, `find_button(...)`, `have_button(...)`.
2. **Role-scoped Capybara finders**: `find(:button, "...")`, `within(:section, "Leaderboard") { ... }`.
3. **ARIA / data attributes** when there is no visible text: `find('[aria-label="..."]')`, `find('[data-testid="..."]')`.
4. **CSS selectors** as a last resort.
5. **`page.execute_script`** only when the browser fundamentally cannot otherwise do what the test needs (synthesizing custom events, etc. — see below).

If a button has no visible text (icon-only, etc.), add an `aria-label` to the component rather than scraping a selector in the test.

### Good

```ruby
click_button("Show all activities")
expect(find_button("Show all activities")["aria-pressed"]).to eq "true"
expect(page).to have_button("Hide all activities")
```

### Bad

```ruby
find('[data-action="click->punch#showAll"]').click
expect(page).to have_css('button[aria-pressed="true"]')
page.execute_script("document.querySelector('.show-all-btn').click()")
```

## ActionCable broadcasts: do the real thing

The project's `:test` cable adapter inherits from `:async`, so broadcasts in the test process do round-trip to the browser. **Don't synthesize `turbo:morph-element` events with `execute_script` to fake an ActionCable refresh** — call the real broadcaster (`Component.broadcast_replace_to`, `broadcast_refresh_current!`, etc.) and let Capybara wait for the morphed DOM.

Make a small helper that prepares the data, broadcasts, and waits for an unambiguous post-morph element:

```ruby
def morph_in_punch(user:, date_string:)
  competition_user = CompetitionUser.find_by!(user:, competition:)
  FactoryBot.create(:competition_activity, competition_user:,
    distance_meters: 16_093, start_at: Time.parse("#{date_string}T15:00:00Z"))
  Leaderboard::PunchcardWrapper::Component.broadcast_refresh_current!
  expect(page).to have_css(punch_selector(user_slug: user.slug, date_string:), wait: 5)
end
```

The trailing `expect(...).to have_css(..., wait: 5)` is the synchronization barrier — the test only proceeds once the morph has actually rendered.

## When `execute_script` is genuinely needed

Some browser events can't be produced by a real user action — `popstate`, certain keyboard events, etc. In those cases:

- Keep the script as small as possible.
- Add a comment explaining *why* JS is needed instead of a click.
- Pass values via `arguments[N]` rather than interpolating them into the script string.

If you find yourself reaching for `execute_script`, double-check whether a real user action (real broadcast, real button click, real `visit page.current_url` for reload) would do the same thing — most of the time it will.

## Other conventions

- File the spec at `spec/integration/<feature>/<scenario>_spec.rb`.
- Top-level description is a string (`describe "Landing page"`), not a class.
- Always include `:js, type: :system`.
- When the spec depends on the current date/time, freeze it with `around { |ex| travel_to(Time.parse("...")) { ex.run } }`.
- Define a few small DSL-style helpers in the file (`def container_for(user)`, `def punch_selector(...)`) when they make assertions readable. Don't reach for `page.execute_script` to replace what a helper method could do in Ruby.
