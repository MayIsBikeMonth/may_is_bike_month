---
name: rspec-testing
description: >-
  Bike Index's RSpec testing conventions — how to structure specs with
  `context` and `let`, what kinds of tests to write, and what to avoid
  (mocks, controller specs, testing private methods). Trigger when writing
  or modifying any `*_spec.rb` file, adding test coverage for new code,
  refactoring tests, or designing the test layout for a new feature.
  Includes Good/Bad examples of the project's preferred style.
---

# RSpec testing in Bike Index

This project uses RSpec. All business logic should be tested.

## What to test (and what not to)

- Tests should either: help make the code correct now, or prevent bugs in the future. Don't add tests that don't do one of those things.
- Use **request specs**, not controller specs. Everything making the same request should be in a single test.
- Avoid testing private methods.
- Avoid mocking objects.
  - If making external requests, use VCR. Don't manually write VCR cassettes — record them by running the tests.

## Always fix failing tests

If `rspec` reports failures — even ones that look unrelated to your change, even ones you can show were already failing on `main` via `git stash` — **fix them before shipping**. A red suite is broken whether or not you broke it. Do not write off failures as "pre-existing", "flaky", "chromedriver-related", or "not from this PR" and move on.

The expected order of operations when a failure surfaces:

1. Reproduce it deterministically (rerun the single spec file; check `tmp/capybara/*.png` for system specs).
2. Diagnose the actual cause — is the test wrong, the code wrong, or is infrastructure (chromedriver, fixtures, time-zone, asset pipeline) misconfigured?
3. Fix it. If it's outside the scope of the current PR, fix it in a separate PR *first* and rebase, rather than landing on top of red.
4. Only if the fix is genuinely blocked (needs a credential you don't have, needs a product decision) surface it to the user with what you tried and what you need to unblock — don't just note it and ship.

Reporting "the failures pre-date this branch" is not a resolution. If you find yourself writing that sentence, stop and fix the tests instead.

### Watch out for misleading stack traces in system specs

System specs (`type: :system`, `:js`) need the asset pipeline built. If `app/assets/builds/tailwind.css` is missing, every Tailwind utility (`.hidden`, `.opacity-0`, etc.) silently no-ops — elements that should be hidden render visible, Capybara's `expect(x).not_to be_visible` fails, and subsequent `.click`/`.hover` calls on the unexpectedly-laid-out page can produce chromedriver crash dumps that *look* like a driver/browser problem. Before blaming chromedriver, run `bin/rails tailwindcss:build` (or start `bin/dev`) and rerun.

## Structuring with `context` and `let`

Use `context` and `let` to isolate what varies between examples. Each `it` block should live in a `context` that names the condition, with `let` overrides for only what differs in that case. **Avoid repeating setup across sibling `it` blocks.**

### Good

```ruby
describe "show_bulk_import?" do
  let(:organization) { FactoryBot.build(:organization, pos_kind:) }
  let(:pos_kind) { "no_pos" }

  it "is falsey" do
    expect(organization.show_bulk_import?).to be_falsey
  end

  context "when ascend" do
    let(:pos_kind) { "ascend_pos" }

    it "is truthy" do
      expect(organization.show_bulk_import?).to be_truthy
    end
  end

  context "when broken_ascend_pos" do
    let(:pos_kind) { "broken_ascend_pos" }
    it "is truthy" do
      expect(organization.show_bulk_import?).to be_truthy
    end
  end

  context "when lightspeed_pos" do
    let(:pos_kind) { "lightspeed_pos" }
    it "is truthy" do
      expect(organization.show_bulk_import?).to be_falsey
    end
  end

  context "when feature show_bulk_import_impound" do
    let(:organization) { FactoryBot.build(:organization_with_organization_features, enabled_feature_slugs: ["show_bulk_import_impound"]) }
    it "is truthy" do
      expect(organization.show_bulk_import?).to be_falsey
    end
  end
end
```

### Bad

```ruby
it "returns truthy for show_bulk_import?" do
  organization = FactoryBot.create(:organization, pos_kind: "ascend_pos")
  expect(organization.show_bulk_import?).to be_truthy
end
it "returns truthy when feature is included" do
  organization = FactoryBot.create(:organization)
  allow(organization).to receive(:any_enabled?) { true }
  expect(organization.show_bulk_import?).to be_truthy
end
```

The bad version repeats setup, mocks the object, and doesn't communicate what each case represents.
