---
name: integration-testing
description: >-
  May is Bike Month conventions for browser specs (`type: :system, :js`)
  — every example pays a Selenium boot cost, so bias hard toward fewer,
  denser examples that walk through state via clicks, prefer
  named-element matchers over CSS selectors or `execute_script`, and
  combine same-setup work into one `it` even when scenarios feel
  independent. **Consult this skill any time you create or modify a
  `:js, type: :system` spec** — that includes everything under
  `spec/integration/` AND component system specs at
  `spec/components/**/*_system_spec.rb`; the rules apply equally to
  both. Read alongside the `rspec-testing` skill for the project's
  general `context`/`let` style.
---

# Integration testing in May is Bike Month

Browser specs (`type: :system, :js`) live in two places: feature flows under `spec/integration/` and component-level interaction specs at `spec/components/**/*_system_spec.rb`. Both run full Chrome sessions via Capybara/Selenium and pay a real Selenium boot cost per example, so the same conventions apply to both: optimize for fewer, denser examples and high-level Capybara helpers.

The general `context`/`let` style and "what to test" rules are in the [`rspec-testing`](../rspec-testing/SKILL.md) skill — the rules below extend it for the system-spec case.

## One `it` per setup; many assertions per `it`

Unit specs prefer one assertion per example. **Integration specs prefer the opposite**: when several assertions share the same fixture and the same initial `visit`, fold them into one example that walks through state transitions (click → assert → click → assert).

Use `context` only when the *setup* differs — a different `let!`, a different page, a different feature flag. Don't split a single user flow across sibling `it` blocks just because each step has its own assertion.

**Combine same-setup work, even when scenarios feel independent.** Before writing a new `describe`/`context`/`it`, read the existing file and find an example whose fixtures and initial `visit` match what you need — then append your clicks/assertions to it. It's tempting to leave a separate `it` for things that feel like different concerns ("button-state test", "morph-capture test", "URL persistence test", "footer localization test"). Don't. A long, sectioned-with-comments example pays one Selenium boot; four short examples pay four. Failure attribution is fine — the failed line number tells you exactly which phase broke. Only add a new block when the setup genuinely differs.

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

## Carry state forward, don't reset between phases

You know what state the page is in after each click — write the next assertion against that state. Don't `click_button("Hide all activities")` between phases just to get a clean slate; resets cost a click (often two — clear, then re-establish), obscure what's actually happening, and tempt you to think of each phase as an isolated scenario rather than as one continuous user flow.

If a carried-over state makes the next assertion awkward, that's information: usually you can reorder or rephrase phases so the previous phase's end state is exactly what the next phase needs to start from. Treat the example as a flow with state advancing through it, not a sequence of independent scenarios each demanding a pristine baseline.

`visit page.current_url` is a reload, not a reset — use it specifically to verify URL persistence across a fresh page load. Otherwise, prefer letting state flow.

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

The project's `:test` cable adapter inherits from `:async`, so broadcasts in the test process do round-trip to the browser. **Don't synthesize `turbo:morph-element` events with `execute_script` to fake an ActionCable refresh** — call the real broadcaster (`Component.broadcast_replace_to`, `broadcast_refresh_current!`, etc.) and let Capybara's wait do the synchronization.

The pattern is: prepare the data the broadcast will render → call the real broadcaster → assert on an unambiguous post-morph element with a `wait:` (e.g. `expect(page).to have_css(some_new_selector, wait: 5)`). The trailing wait is the synchronization barrier — the test proceeds only once the morph has actually rendered.

## Build Tailwind before running system specs

CI builds `app/assets/builds/tailwind.css` automatically; your local sandbox does not. Without it, Tailwind utility classes (most importantly `hidden` → `display: none`) silently don't apply, and assertions like `expect(tooltip).not_to be_visible` fail in confusing ways that look like flakes but aren't.

**Before running any `:js, type: :system` spec locally, run `bin/rails tailwindcss:build`** (or have `bin/dev` running, which watches and rebuilds). If a system spec is failing on visibility/styling assertions, check `app/assets/builds/tailwind.css` exists and is recent before assuming the test or component is broken.

## Other conventions

- Always include `:js, type: :system`.
- Define a few small DSL-style helpers in the file (`def container_for(user)`, `def punch_selector(...)`) when they make assertions readable. Don't reach for `page.execute_script` to replace what a helper method could do in Ruby.
