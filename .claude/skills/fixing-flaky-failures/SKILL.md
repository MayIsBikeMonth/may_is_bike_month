---
name: fixing-flaky-failures
description: >-
  How to fix a test that fails intermittently — one that passes locally but
  fails on CI, passes on re-run, or is already tagged `:flaky`. **Read this
  before touching any spec that is failing intermittently, and before adding,
  raising, or relying on a `flaky:` tag or a `wait:` bump.** Trigger on a CI
  failure the user calls flaky, unreliable, intermittent, "green locally",
  "passes on retry", "fix CI", or a pasted `gh run`/Actions URL whose failure
  isn't reproducible; also whenever you catch yourself about to delete, skip,
  loosen, or retry an assertion to make a red build go green. **Equally: any
  spec that fails intermittently while you verify your own work.**
---

# Fixing flaky failures

## The rule that overrides everything else here

**You may not reduce test coverage to make a flaky test pass.** Not as a last resort, not "temporarily", not when the coverage looks redundant.

All of these are reducing coverage, and none of them is a fix:

- Deleting an assertion, a step, a helper call, or a whole example.
- Loosening a matcher so it can't fail (`have_css(count: 2)` → `have_css`, an exact string → a regex, `have_no_content` → nothing).
- `skip`/`pending`/`xit`.

If the only fix you can see requires giving up coverage, that is a decision for the user — describe what you'd give up and ask. Announcing a scope reduction afterwards is not the same as getting agreement.

The exception that isn't one: if the assertion is *wrong* — it asserts behaviour the app never promised — fixing it is correcting a bad test. Say explicitly why it was wrong.

## Retries and longer waits: allowed, but earn them first

`:flaky` and a bigger `wait:` keep every assertion and still require it to pass. They're a legitimate last resort, not the first thing you try.

- Diagnose first (below). A retry over a findable cause just makes it intermittent for longer.
- Leave a comment saying what you found and why the retry stands in for a fix. A bare `flaky: true` tells the next person nothing.
- Say plainly in your summary that you papered over it rather than fixed it.

A retry is the *wrong* answer when the example fails through all its retries (the cause is structural), or when you can't say what a wait is waiting for.

**`click_button(wait:)` doesn't extend the click.** It covers finding the button; the navigation the click starts gets `Capybara.default_max_wait_time`. `using_wait_time(10) { click_button ... }` covers both.

## Diagnose before you touch anything

### 1. Get the real failure, not the summary

```bash
gh run view <run-id> --json jobs --jq '.jobs[] | "\(.databaseId) \(.name) \(.conclusion)"'
gh run view --job <job-id> --log-failed | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'Failure/Error|expected|rspec ./spec'
```

### 2. Read the message literally

The exact failure text usually names the mechanism. A nil `current_path`, for example, isn't "the click was lost" — it means the URL had no path: `about:blank`, `chrome-error://chromewebdata` (a navigation failed), or `""` (no document committed yet). Check the matcher's source when a message is surprising.

### 3. Instrument rather than theorise

Copy the spec to a scratch file, record the events the app actually emits, and run it — a log beats an argument:

```ruby
page.execute_script(<<~JS)
  window.__events = []
  const stamp = (name, extra) => window.__events.push(Object.assign({name, t: Math.round(performance.now())}, extra))
  document.addEventListener("turbo:before-fetch-response", (e) => {
    stamp("response", {target: e.target?.id, url: e.detail?.fetchResponse?.response?.url})
  })
JS
# ...drive the spec...
# A file, not puts - rtk's rspec wrapper drops the run's stdout
File.open("tmp/probe.log", "a") { |f| page.evaluate_script("window.__events").each { |e| f.puts e.inspect } }
```

Parameterise the scratch spec over the variable you suspect (`[0, 8].each do |delay|` around an injected `sleep`) so one run compares fast and slow paths. Delete the scratch file when done.

### 4. Try to reproduce, and treat failure-to-reproduce as information

```bash
for i in 1 2 3; do bundle exec rspec <the spec file> 2>&1 | grep -E "examples, " | tail -1; done
```

Green locally doesn't mean "add a retry". It narrows the cause to something CI has and you don't: **contention** (browser, Rails and Postgres sharing one runner) or **ordering** (a different seed, or state left by another example).

For contention, slow the browser alone rather than the machine — Selenium's Chrome driver exposes CDP:

```ruby
page.driver.browser.execute_cdp("Emulation.setCPUThrottlingRate", rate: 6)
```

A rate that leaves the spec green over ~20 runs is evidence, not proof.

### 5. Blaming your own change needs both arms measured together

"Is this spec flaky?" and "did my change make it flaky?" are different questions. Local load drifts, so samples taken at different times aren't comparable. Revert *only* the suspect change and run both arms the same number of times, back to back. Small samples can't separate a 17% failure rate from a 7% one.

Rule out ordering first: RSpec prints `Randomized with seed N`, and `--seed N` replays it. A failing seed that passes on replay leaves timing.

Measure the "without the fix" arm against the base ref by name — `git checkout origin/main -- <paths>`. Once the fix is committed, `git checkout -- <paths>` restores *it*. Save an uncommitted fix first: `git diff HEAD -- <paths> > tmp/flaky_fix.patch`, then restore with `git checkout HEAD -- <paths> && git apply tmp/flaky_fix.patch`.

## Known causes

**Not actually flaky — the environment is wrong.** A missing or stale `app/assets/builds/tailwind.css` makes `hidden` and friends silently not apply, so visibility assertions fail in ways that read as flakes. A build that predates a merge fails the same way: the class is in the source but wasn't in the content scan. `bin/rails tailwindcss:build` is the fix (see `sandbox-test-setup`). Same class of thing: an unmigrated test DB, a stale VCR cassette. Three identical failures with no ordering component is this, not a flake.

**Interacting before Stimulus controllers connect.** A freshly rendered page answers to no controller until it connects — a click or `fill_in` can land before the listener exists. Wait on something the controller renders or changes before interacting.

**Clicking something that is being re-rendered.** A Turbo frame that reloads or a stream that replaces the element detaches it mid-click. Wait for the settled state the user would wait for, then click:

```ruby
expect(page).to have_css("turbo-frame#results_frame[complete]:not([busy])", wait: 10)
```

**Filling a field while a turbo-stream renders.** Turbo restores focus a frame after a stream render, so a `fill_in` in that frame can type into the wrong field. Wait for the stream's result first.

**A probe that measures itself instead of the app.** `event.defaultPrevented` read *inside* a `document` listener only reflects listeners that already ran. Defer the read (`setTimeout`) so every listener has had its turn, and record the verdict for both outcomes so a wrong verdict fails loudly instead of timing out.

## What a finished fix looks like

- The change names a mechanism ("the frame reloads and detaches the link"), not a symptom ("flaky on CI").
- You can explain why the fix addresses that mechanism.
- Where you fell back to a retry or a longer wait, you say so as the headline, and the spec comment records what you ruled out.
- Comments describing the flake are corrected if your diagnosis contradicts them.
- CI is the only real verification.

## The `flaky:` tag

`spec/rails_helper.rb` retries `flaky:`-tagged examples twice, but only when `RETRY_FLAKY` is set — and `.github/workflows/ruby.yml` doesn't set it, so the tag currently does nothing on CI either. Adding a tag doesn't paper over anything until the workflow sets `RETRY_FLAKY`; raise that with the user rather than assuming retries run.

Removing a now-unnecessary `flaky:` tag after you've fixed the cause is good housekeeping.
