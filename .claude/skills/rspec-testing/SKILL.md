---
name: rspec-testing
description: >-
  May is Bike Month's RSpec testing conventions — how to structure specs with
  `context` and `let`, what kinds of tests to write, and what to avoid
  (mocks, controller specs, testing private methods). Trigger when writing
  or modifying any `*_spec.rb` file, adding test coverage for new code,
  refactoring tests, or designing the test layout for a new feature.
  Includes Good/Bad examples of the project's preferred style.
---

# RSpec testing in May is Bike Month

This project uses RSpec. All business logic should be tested.

## Run only the specs your change touches

Run the spec files for what you changed, not the whole suite. When something fails outside those files, re-run that spec file on its own first: failing alone means it's real and gets fixed, never excused as pre-existing; passing alone is the [`fixing-flaky-failures`](../fixing-flaky-failures/SKILL.md) skill, whose first rule is that you can't reach for a retry, a looser matcher, or a deleted assertion to make it green.

## What a spec prints doesn't reach you

rtk's rspec wrapper reports a summary in place of the run's output, which costs you two different things. A `puts` added to a scratch spec to inspect a value vanishes and the run reads as an ordinary pass — redirect it (`bundle exec rspec spec/foo_spec.rb > tmp/probe.log 2>&1`) or write to a file from inside the example, as [`fixing-flaky-failures`](../fixing-flaky-failures/SKILL.md) does for browser-side values. **A failure keeps its `ExpectationNotMetError:` line but loses the expected/got values under it**, so re-running the one example tells you no more than the first run did; `rtk proxy bundle exec rspec <file>:<line>` is what shows them. `--format documentation` rescues neither.

## What to test (and what not to)

- Tests should either: help make the code correct now, or prevent bugs in the future. Don't add tests that don't do one of those things.
- Use **request specs**, not controller specs — request specs go through the full middleware/routing stack, so they catch breakage controller specs can't see. Everything making the same request should be in a single test. For markup a component owns, see [A component's own markup](#a-components-own-markup-is-tested-in-its-component-spec).
- Avoid testing private methods.
- Avoid mocking objects.
  - If making external requests, use VCR. Never write or edit a cassette by hand — record them by running the tests (see [VCR cassettes](#vcr-cassettes-never-hand-edit-always-re-record)).
- Don't use `tap` to bundle factory creation with follow-up setup. Create the record in `let`/`let!`, then do the follow-up work on its own line (a separate statement, or a `before` block). One thing per line reads better and keeps the factory call clean.

### Good

```ruby
let!(:competition_user) { FactoryBot.create(:competition_user, user:) }
before { competition_user.update(included_in_competition: false) }
```

### Bad

```ruby
let!(:competition_user) do
  FactoryBot.create(:competition_user, user:).tap do |competition_user|
    competition_user.update(included_in_competition: false)
  end
end
```

## A component's own markup is tested in its component spec

What a component decides about its markup — a label, a placeholder, a class, whether a field renders at all — belongs in `spec/components/**/component_spec.rb`, not in the request spec for a page that happens to render it. Request specs cover the request: status, redirects, what was saved, what the page is wired to.

A component having no spec yet isn't a reason to put it in the request spec instead.

**No stylesheet loads in a component spec, so Capybara calls anything hidden by a class visible.** `have_no_field`/`visible: false` against a `hidden` wrapper fails with "found 1 match", which reads as the component rendering the wrong thing. Assert the wrapper instead — `page.find("div.hidden input[name='additional']", visible: :all)` — and leave real invisibility to a `:js` system spec.

## VCR cassettes: never hand-edit, always re-record

**Never open a cassette and change it.** Not a URL, not a token, not a timestamp, not an interaction — no matter how small or how obviously right the edit looks. A cassette is a recording of what a real service (Strava) actually said; an edited one asserts something no service ever returned, and the spec passes against a fiction. This has no exceptions.

The only way a cassette changes is a spec run that records it:

- **Stale or wrong contents** — `rm` the file and run the spec. VCR writes it from scratch, holding exactly the requests the spec makes now. Re-recording *without* deleting only writes back the requests still being made, so interactions the spec has stopped making survive forever.
- **Cassette missing for a resource that doesn't exist yet** — leave it absent and the spec red. Don't fabricate one.
- **Secrets** — `spec/rails_helper.rb`'s `filter_sensitive_data` and `before_record` handle them. Add the key there; don't scrub the file by hand.

**Commit what a run re-records.** A modified cassette is a re-recording, not unrelated churn. Commit it on the branch you're on, whatever that branch is about. Never `git checkout` it away to keep a diff focused.

`git status` after a spec run is the only signal; a run that re-records prints nothing.

**Never write `WebMock.stub_request`. HTTP in a spec is a cassette, with no exceptions.** A stub asserts what you imagined a service returns; a cassette records what it actually returned, which is the same reason cassettes are never hand-edited.

## Stubbing ENV

Never partial-mock `ENV` with `allow(ENV).to receive(:[]).and_call_original` — it makes every subsequent `ENV[...]` lookup go through RSpec's message router, which is slow and easy to break by forgetting a `.with(...)` branch.

Use `stub_const` against a merged hash instead:

### Good

```ruby
stub_const("ENV", ENV.to_hash.merge("STRAVA_CLIENT_ID" => "12345"))
```

### Bad

```ruby
allow(ENV).to receive(:[]).and_call_original
allow(ENV).to receive(:[]).with("STRAVA_CLIENT_ID").and_return("12345")
```

## Drain Sidekiq jobs, don't run them inline

`spec/rails_helper.rb` sets `Sidekiq.testing!(:fake)`. Run enqueued jobs by draining them — `UpdateCompetitionUserJob.drain` for one job, `Sidekiq::Job.drain_all` for everything (clear first with `Sidekiq::Job.clear_all` when earlier setup left jobs queued). Don't wrap the exercise in `Sidekiq::Testing.inline!`. Draining lets the request finish and commit before the jobs run, against that committed state — the way production does it — and keeps the test from silently pulling in every cascading job.

## Always fix failing tests

Fix every failing test, even ones that were already failing on `main`. Confirming a failure pre-dates your branch (via `git stash` or checking out `main`) explains *what* broke — not whether you fix it. You fix it.

## Don't weaken assertions to make a failing test pass

Reproduce the failure and find out what changed before touching the expectation. Changing an expected value to whatever now renders, loosening `eq` to `include`, dropping a `count:`, or deleting the assertion with a "looks unrelated" handwave all erase signal rather than fix anything. Fix the code if the original assertion was right; update it — with a comment — if the behaviour intentionally changed. The [`fixing-flaky-failures`](../fixing-flaky-failures/SKILL.md) skill has the same rule for the intermittent case, where it is absolute.

## Match a target attributes hash, not one attribute at a time

When you're checking several fields on the same object or response, build one expected-attributes hash and assert against it in a single matcher. Don't write a chain of one-attribute-per-line `expect`s.

- Object (ActiveRecord, plain Ruby): `expect(record).to have_attributes(target_attributes)`
- Hash (JSON response, parsed body): `expect(hash).to eq(target.as_json)` for full match, or `expect(hash).to include(target_attributes)` for partial.

This collapses what would be 4 brittle assertions into 1, makes the *contract* visible at a glance, and gives a single readable diff when something changes. It also avoids the trap of weak per-field assertions like `expect(x).to be_present` or `expect(url).not_to include("blank.png")` standing in for "the right value" — match the value directly.

### Good

```ruby
target_attributes = {kind: "found", impounded_description: "Some description"}
expect(impound_record).to have_attributes(target_attributes)

expect(json_result["memberships"]).to eq([target_membership.as_json])
```

### Bad

```ruby
expect(impound_record.kind).to eq("found")
expect(impound_record.impounded_description).to be_present
expect(impound_record.impounded_description).to eq("Some description")

logo_url = json_result["memberships"].first["organization_logo_url"]
expect(logo_url).to be_present
expect(logo_url).not_to include("blank.png")
expect(logo_url).to eq(organization.avatar_url)
```

The bad version spreads one logical assertion across many lines, mixes weak presence checks with the real expected value, and produces noisier failure output.

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

## One example per distinct setup — combine same-setup `it` blocks

`context`/`let`/`before` isolate what *varies*. The corollary runs the other way: if two sibling `it` blocks share the **same** setup — no differing `context`, `before`, or `let` override between them — collapse them into **one** example. Each distinct setup earns exactly one `it`; put all of that setup's assertions (and all of its requests/renders) in that single block.

This is the same instinct as "everything making the same request should be in a single test", generalized: splitting same-setup assertions across sibling `it` blocks re-runs identical setup (factories, HTTP requests, renders) once per block for zero isolation benefit, and scatters one logical behavior across the file. Two `it` blocks that differ *only* in the request params or the assertion — with identical `let`s and no `before` between them — are one example.

After writing a spec, scan each `context`/`describe`: if it holds multiple `it` blocks and they don't each sit behind a distinct `context`/`before`/`let`, merge them.

**Not when the first request changes what the next one does.** Same setup isn't the same starting state once a request has run: signing in consumes `session[:user_return_to]`, for example. Leave those as sibling contexts with a `let` for what differs, and say in a comment why they can't share one example — otherwise the next cleanup pass merges them again.

**A helper that reads the response has to be a `def`, not a `let`.** One example making several requests is exactly where a `let` that parses `response.body` bites: it memoizes the first response and every later assertion re-reads it, so the example fails while the code is right (or worse, passes while the code is wrong). `def` re-evaluates — `json_result` in `spec/support/request_spec_helpers.rb` is a `def` for this reason.

### Good

```ruby
context "signed in as admin" do
  include_context :logged_in_as_admin

  it "renders the index, with and without the chart" do
    get base_url
    expect(response.code).to eq "200"
    expect(assigns(:render_chart)).to be_falsey

    get "#{base_url}?render_chart=true&period=week"
    expect(response.code).to eq "200"
    expect(assigns(:render_chart)).to be_truthy
  end
end
```

### Bad

```ruby
context "signed in as admin" do
  include_context :logged_in_as_admin   # signs in again for every it below

  it "renders" do
    get base_url
    expect(response.code).to eq "200"
    expect(assigns(:render_chart)).to be_falsey
  end
  it "renders the chart" do
    get "#{base_url}?render_chart=true&period=week"
    expect(response.code).to eq "200"
    expect(assigns(:render_chart)).to be_truthy
  end
end
```
