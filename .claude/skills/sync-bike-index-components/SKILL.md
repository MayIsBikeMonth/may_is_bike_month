---
name: sync-bike-index-components
description: >-
  Pull updates from bikeindex/bike_index view components, stimulus controllers,
  and the binxtils gem/JS package into this app. Use when asked to "sync from
  bike_index", "pull bike_index updates", "update binxtils", or to apply a
  specific bike_index PR to this repo.
allowed-tools: Bash, Read, Edit, Grep, Glob, Write
---

# Sync bike_index components into may_is_bike_month

This app shares its UI component library and `binxtils` gem with
`bikeindex/bike_index`. Components in `app/components/ui/`, the matching
stimulus controllers in `app/javascript/controllers/ui/`, and `binxtils` itself
all originate there. Bike_index is the source of truth; this app pulls from it
periodically.

## What to sync vs. what to skip

`may_is_bike_month` is a forked design — bike_index uses blue/gray on Bootstrap
foundations, this app uses purple on a clean Tailwind reset. **Skip styling and
naming differences**, even when they look substantive at first:

- **`tw:` class prefix** — bike_index namespaces every Tailwind class with `tw:`
  to disambiguate from its legacy bootstrap CSS. This app does not. If the only
  diff is `class="foo"` vs `class="tw:foo"`, skip it.
- **Color palette** — bike_index uses `blue` for primary and `gray` for neutrals;
  this app uses `purple` and a different neutral. Color-name swaps in CSS classes
  are intentional fork divergence.
- **App-specific previews and fixtures** — `component_preview.rb` and
  `*_spec.rb` files often reference bike_index models (`Bike`, `Payment`, etc.).
  Keep this app's preview content; substitute factories when porting specs (see
  Step 4).

**Do pull in:**

- Functional logic changes (new params, bug fixes, new methods)
- Stimulus controller behavior changes (event handlers, lifecycle hooks, new
  interactions like z-index stacking or debounced resize handlers)
- Test additions that exercise new behavior (adapt to local factories)
- ViewComponent convention fixes (e.g., `link_to` → `helpers.link_to`)
- `binxtils` gem version bumps and the matching `@bikeindex/time-localizer`
  npm pin in `config/importmap.rb` (these move in lockstep — see Step 3)

**When in doubt**, leave the file unchanged and note it for review. Quiet
divergence is recoverable; an unwanted change isn't until someone notices.

## Step 1: Clone bike_index for local diffing

The full repo is large; do a shallow blobless clone into `.context/`
(gitignored). Use a subshell so a failure inside doesn't leave the working
directory in a surprising place:

```bash
mkdir -p .context && (cd .context && \
  gh repo clone bikeindex/bike_index -- --depth=1 --filter=blob:none)
```

If the clone already exists from a previous sync, `cd .context/bike_index &&
git pull` (or just `rm -rf .context/bike_index` and reclone — it's small).

## Step 2: Diff each shared component

```bash
for dir in alert badge button button_link card chart definition_list dropdown \
           header loading_spinner modal pagination table table_column time tooltip; do
  echo "===== ui/$dir ====="
  diff -rq "app/components/ui/$dir" ".context/bike_index/app/components/ui/$dir" 2>&1
done
```

For each diff, open both files and judge against the rules above. To filter out
the styling noise quickly:

```bash
diff app/components/ui/<name>/component.rb \
     .context/bike_index/app/components/ui/<name>/component.rb \
  | grep -v 'tw:' | grep -v -E '(blue|purple|gray)-[0-9]'
```

Lines remaining after the filter are usually the substantive diffs worth reading.

Also diff stimulus controllers:

```bash
for f in alert dropdown modal table tooltip; do
  echo "===== $f ====="
  diff "app/javascript/controllers/ui/${f}_controller.js" \
       ".context/bike_index/app/javascript/controllers/ui/${f}_controller.js"
done
```

### Surface new components

Bike_index sometimes adds whole new components (e.g., `period_select`,
`time_localizer`, `address_display`) that don't exist here yet. The fixed list
above won't catch them — list bike_index's UI directory and compare:

```bash
comm -23 \
  <(ls .context/bike_index/app/components/ui/ | sort) \
  <(ls app/components/ui/ | sort)
```

A new component isn't an "update" — porting one is bigger work (new files,
controllers, locales, wiring). Surface the candidate to the user with what
porting would entail, rather than silently adding it.

## Step 3: Update binxtils gem and time-localizer JS together

These move in lockstep: the gem's `Binxtils::SetPeriod#set_timezone` reads a
`timezone` cookie that the JS package's `TimeLocalizer` constructor writes. A
gem bump that expects new cookie behavior needs the matching JS bump (and vice
versa) or the chain breaks silently — server falls back to its own zone.

To find the paired versions, check the bike_index PR that bumped them:

```bash
gh pr list --repo bikeindex/bike_index --search "binxtils" --state merged --limit 5
gh pr view <N> --repo bikeindex/bike_index   # read the body for "gem X / npm Y"
```

Then bump both:

```bash
bundle update binxtils
```

And the JS pin in `config/importmap.rb`:

```ruby
pin "@bikeindex/time-localizer", to: "https://cdn.jsdelivr.net/npm/@bikeindex/time-localizer@<NEW_VERSION>/dist/index.js"
```

Confirm both landed by checking `Gemfile.lock` for the new gem version and
diffing `config/importmap.rb`.

## Step 4: Apply a specific PR's diff

When the user references a bike_index PR (`gh pr view <N> --repo bikeindex/bike_index`,
`gh pr diff <N> --repo bikeindex/bike_index`), walk each file in the diff. Use
the same substantive-vs-cosmetic rules from "What to sync vs. what to skip":

- Files in `app/components/ui/`, `spec/components/ui/`,
  `app/javascript/controllers/ui/`, `config/importmap.rb`, `Gemfile.lock` —
  these are the shared surface. Apply substantive changes; skip `tw:` prefix
  and color-name swaps.
- Files in `app/views/`, `app/controllers/`, `app/helpers/`,
  `config/locales/`, `spec/integration/`, `app/views/shared/` — bike_index-app
  surface. Skip unless the path also exists here and the change is generic.
- Files in `Gemfile` — usually skip; the version constraint style differs.
  Apply the *intent* (e.g., bump to a new version) by running `bundle update`.

For test additions, bike_index specs commonly reference factories that don't
exist here (`Payment`, `Bike`, `Organization`). Substitute a local factory with
a `created_at` column — `competition_activity` or `competition_user` are usually
the right shape. Keep the assertion structure; only swap the model and class
references.

## Step 5: Verify

Build assets first — system specs depend on Tailwind being compiled. A missing
`app/assets/builds/tailwind.css` makes every utility (`hidden`, `opacity-0`,
etc.) silently no-op, which surfaces as Capybara `not_to be_visible`
assertions failing and chromedriver crash dumps that *look* infrastructural
but aren't:

```bash
bin/rails tailwindcss:build
```

Then run the suites and the linter:

```bash
bundle exec rspec spec/components/        # includes :js system specs
bundle exec rspec spec/                   # full suite
bin/lint
```

**Do not write off failures as "pre-existing" or "flaky."** A red suite is
broken whether or not the sync caused it. If a spec was failing on `main`
before the sync, fix it as part of this PR (or as a separate PR landed first)
— don't leave the next person with the same red suite. See the
`rspec-testing` skill's "Always fix failing tests" section for the full rule.

## Cleanup

The `.context/bike_index/` clone is gitignored and can be left in place for
future syncs, or removed with `rm -rf .context/bike_index`.
