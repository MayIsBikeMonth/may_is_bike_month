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
all originate there. This skill covers periodic sync.

## What to sync vs. what to skip

`may_is_bike_month` is a forked design — it intentionally diverges from
bike_index in two large categories. **Skip those diffs**, even when they look
substantive at first glance:

- **`tw:` class prefix** — bike_index namespaces every Tailwind class with `tw:`
  (its config has legacy bootstrap CSS to disambiguate). This app does not. If
  the only diff is `class="foo"` vs `class="tw:foo"`, skip it.
- **Color palette** — bike_index uses `blue` for primary actions and `gray` for
  neutrals; this app uses `purple` and a different neutral. Color-name swaps in
  CSS classes should not be pulled in.
- **App-specific previews** — `component_preview.rb` files often reference
  bike_index models (`Bike`, `Payment`, etc.). Keep this app's preview content.

**Do pull in:**

- Functional logic changes (new params, bug fixes, new methods)
- Stimulus controller behavior changes (event handlers, lifecycle hooks)
- Test additions that exercise new behavior (adapt fixtures to local factories)
- ViewComponent convention fixes (e.g., `link_to` → `helpers.link_to`)
- `binxtils` gem version bumps and the matching `@bikeindex/time-localizer`
  npm pin in `config/importmap.rb`

When in doubt, leave the file unchanged and note it for review.

## Step 1: Clone bike_index for local diffing

The full repo is large; do a shallow blobless clone into `.context/` (gitignored):

```bash
mkdir -p .context && cd .context && \
  gh repo clone bikeindex/bike_index -- --depth=1 --filter=blob:none
cd -
```

## Step 2: Diff each shared component

```bash
for dir in alert badge button button_link card chart definition_list dropdown \
           header loading_spinner modal pagination table table_column time tooltip; do
  echo "===== ui/$dir ====="
  diff -rq "app/components/ui/$dir" ".context/bike_index/app/components/ui/$dir" 2>&1
done
```

For each diff, open both files and judge against the rules above. The fast
filter: pipe through `grep -v '^[<>] .*tw:' | grep -v 'bg-blue\|text-blue\|bg-purple'`
to highlight non-styling lines.

Also diff stimulus controllers:

```bash
for f in alert dropdown modal table tooltip; do
  echo "===== $f ====="
  diff "app/javascript/controllers/ui/${f}_controller.js" \
       ".context/bike_index/app/javascript/controllers/ui/${f}_controller.js"
done
```

## Step 3: Update the binxtils gem and time-localizer JS together

These move in lockstep — the gem reads a cookie that the JS sets. Bump both
when either changes.

```bash
bundle update binxtils
```

Then update the JS pin in `config/importmap.rb`:

```ruby
pin "@bikeindex/time-localizer", to: "https://cdn.jsdelivr.net/npm/@bikeindex/time-localizer@<NEW_VERSION>/dist/index.js"
```

Cross-reference the bike_index PR description for the matching versions —
e.g. PR #3402 paired binxtils 0.4.1 with time-localizer 0.2.1.

## Step 4: Apply a specific PR's diff

When the user references a bike_index PR (`gh pr view <N> --repo bikeindex/bike_index`,
`gh pr diff <N> --repo bikeindex/bike_index`), walk each file in the diff:

- Files in `app/components/ui/`, `spec/components/ui/`, `app/javascript/controllers/ui/`,
  `config/importmap.rb`, `Gemfile.lock` — apply if substantive
- Files in `app/views/`, `app/controllers/`, `app/helpers/`, `config/locales/`,
  `spec/integration/` — bike_index-specific, skip unless the path also exists
  here and the change is generic

For test additions: bike_index specs commonly use `Payment`, `Bike`, or
`Organization` factories that don't exist here. Adapt by substituting a
local factory with a `created_at` column (e.g., `competition_activity`,
`competition_user`).

## Step 5: Verify

```bash
bundle exec rspec spec/components/ --tag '~type:system'
bundle exec rspec spec/  # full non-system suite
bin/lint
```

System specs (`type:system`) require a working chromedriver and are sometimes
flaky/broken on this branch independent of the sync — confirm any system-spec
failures exist before the changes (`git stash && rspec ... && git stash pop`).

## Cleanup

The `.context/bike_index/` clone is gitignored and can be left in place for
future syncs, or removed with `rm -rf .context/bike_index`.
