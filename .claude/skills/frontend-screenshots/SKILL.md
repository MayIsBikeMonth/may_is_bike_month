---
name: frontend-screenshots
description: >-
  Capture desktop+mobile screenshots of May is Bike Month pages from the local
  `bin/dev` server via Playwright MCP, with a seeded-user identity gate that
  keeps PII out of uploaded images. Use whenever a task needs screenshots of
  local pages — PR documentation, bug repros, before/after comparisons across
  branches, design review, demos — including mid-interaction states like an
  open dropdown, a modal showing, a form mid-fill, or a hover. Use it even when
  the user just says "grab a screenshot" or "show me what this looks like"
  without naming Playwright. For a component state that's hard to reach on a
  real page, screenshot its ViewComponent/Lookbook preview URL instead.
  **Also read the filename rule here before any
  `mcp__playwright__browser_take_screenshot` call**, including a one-off
  capture of some other site — it's what keeps PNGs out of the working tree.
allowed-tools: Bash, Read, ToolSearch, mcp__playwright__browser_navigate, mcp__playwright__browser_resize, mcp__playwright__browser_evaluate, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_snapshot, mcp__playwright__browser_wait_for, mcp__playwright__browser_console_messages, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_press_key, mcp__playwright__browser_hover, mcp__playwright__browser_close
---

# Frontend screenshots

Drive Playwright MCP to capture screenshots of pages served by `bin/dev`. Callers
pass `(url-path, page-slug)` pairs, optionally with per-URL interaction steps, and
get back local PNG paths.

## Who runs this

From a session with history, hand this skill to one `general-purpose` subagent (`model: "sonnet"` — it works out how to drive each page; the pages are chosen) that invokes it through the `Skill` tool, briefed with the `(url-path, page-slug)` pairs and any interaction steps per page, who to sign in as (or signed out), and the base ref when the caller wants before/after. It replies with the PNG paths keyed by page, viewport and branch/base, and any capture it couldn't diagnose. It closes the shared Playwright browser when it's done, so finish with any page this session still needs first. A subagent skips this section and does the work itself.

## Output filenames (load-bearing — callers parse these)

`tmp/pr_screenshots/<branch>-<page>-<timestamp>-{desktop,mobile}.png`, where `<branch>=$(git rev-parse --abbrev-ref HEAD | tr '/' '-')` and `<timestamp>=$(date +%Y%m%d-%H%M%S)`. Cross-branch shots get an extra `-base-` segment.

**Every `browser_take_screenshot` anywhere passes a `filename:` starting with `tmp/`** — including a one-off `tmp/tooltip-hover.png` for visual verification that has nothing to do with a PR. The MCP tool's root is the project root, so a bare `tooltip.png` lands in the working tree and shows up in `git status`; `tmp/` is gitignored.

## Preflight

- `eval "$(ruby bin/env --export)"` so `$BASE_URL` is set.
- `curl -fs "$BASE_URL/" >/dev/null` — run it every time, even if an earlier check in the session failed; the user may have started it since. If it fails now, start `bin/dev` yourself in the background (`run_in_background: true`) from the workspace directory and wait for `$BASE_URL/` to answer. `bin/env` resolves `$DEV_PORT`/`$BASE_URL` from the workspace ID, so the bin/dev you start binds the same port and DB the user expects.
- **A 200 doesn't prove the server is this checkout's.** Confirm `ruby bin/env --export` names a `WORKSPACE_ID` first — without one the curl reaches the main checkout. See the `sandbox-test-setup` skill.
- A 200 there doesn't promise the next page renders. A merge from the base can leave the dev DB
  unmigrated, so a passing curl can be followed by `ActiveRecord::PendingMigrationError` on every page.
  `bundle exec rails db:migrate`, and read `log/development.log` before blaming the capture.
  A gem the merge bumped does the same: the running server keeps the version it booted with, so a
  method the new one adds is a `NoMethodError` until `bin/rails restart`.
- If `mcp__playwright__*` tools aren't registered, tell the user to run `claude mcp add playwright -- npx -y @playwright/mcp@latest` and restart.
- **Check the workspace DB has records before planning a real-page capture** — `Competition.count`
  comes back 0 in a workspace whose `db:seed` never ran, so only preview routes render. Seed it
  (`bundle exec rails db:seed` — it's the per-workspace throwaway DB), or capture previews.

## Sign in (with the PII gate)

May is Bike Month authenticates only via Strava OAuth — there is no email/password form. You **cannot script sign-in**; the user must complete the Strava redirect manually in the Playwright MCP browser window. The MCP browser session persists across calls, so this is a one-time step per session. **Only ever authenticate against the local dev server** (`$BASE_URL` / localhost), and never create, promote, or impersonate users to bypass auth.

Most routes don't need sign-in at all — capture anonymous unless the caller specifically needs a signed-in view:

- **Anonymous (default).** Use for public pages: `/`, `/competitions/:id`, `/competitions_original/:id`, `/history`. No sign-in required.
- **Signed in as a seeded user.** Use for `/admin/...` (requires `admin` or `developer` role) or any page that renders user-specific UI. The three seeded users in `db/seeds.rb` are:
  - `seth herr` (strava_id `2430215`, role `developer`) — full admin access. Default when a signed-in shot is needed.
  - `Old Scott` (strava_id `2557663`, role `basic_user`) — non-admin view.
  - `Ali` (strava_id `7645639`, role `basic_user`) — non-admin view.

If a URL redirects (admin pages redirect to root when the user isn't admin/developer), pause and ask the user to sign in via the Playwright browser window with the appropriate Strava account. Don't capture against a redirected page — the screenshot will show the wrong content.

**Verify identity before capturing — but the gate works differently on the application vs. admin layout.**

The dev DB can contain real-looking data. The gates below catch two distinct risks: the wrong-user-signed-in risk (application layout) and the data-on-the-page risk (admin layout).

- **Application layout** (public routes, account, etc.) renders the `UserDropdown::Component`. Check:

  ```js
  document.getElementById('user-menu-button')?.innerText?.trim()
  ```

  The text should start with one of the three seeded `display_name` values (`seth herr`, `Old Scott`, `Ali`). If it's set but doesn't match — **stop and ask** (either you're signed in as a non-seed user, PII risk on upload, or the seeds haven't run: `bundle exec rails db:seed`). For anonymous, expect `user-menu-button` to be absent (`null`/`undefined`) and confirm before continuing.

- **Admin layout** (`/admin/...`) does not render the `UserDropdown::Component` — `#user-menu-button` is always absent regardless of who's signed in, so the application-layout selector is not a sign-in check here. Two signals to use instead:

  1. **Access succeeded** — if you're on `/admin/...` (URL didn't redirect to `/`), the controller's role check passed, so you're at least `admin` or `developer`. That's the only identity signal the admin chrome exposes.
  2. **The PII risk shifts to the data rendered in the page**, not the navbar — admin index pages show full user tables (display name, Strava ID, activities). Before uploading an admin screenshot, **warn the caller that the page contains real user data and ask them to confirm** rather than checking a DOM selector. Don't try to reproduce the application-layout PII gate with a different selector; the gate's job on admin pages is human review.

**Don't capture if any on-page data looks non-seeded.** Even on a public page, if it shows records that don't look like seed data (unfamiliar names, real-looking activities), stop and ask — the dev DB may have been loaded with production data, and screenshots are permanent once uploaded.

## Capture

Make the directory and clear stale shots: `mkdir -p tmp/pr_screenshots && rm -f tmp/pr_screenshots/<branch>-<page>-*.png 2>/dev/null || true` — on the branch capture only: the pattern matches `-base-` shots too, so a cross-branch rerun would delete branch shots its caller hasn't posted yet. `browser_take_screenshot` errors with `ENOENT` rather than creating the directory, so a fresh workspace fails on the first capture.

Two viewports — resize once each, then walk every URL:
1. `browser_resize` 1440×900 → for each URL: navigate → settle → hide the profiler badge → `browser_take_screenshot` (`fullPage: true`) to `...-desktop.png`.
2. `browser_resize` 390×844 → same loop, also `fullPage: true` → `...-mobile.png`.

**Full page, minus the profiler badge, no `target:` arg.** Capture the whole page (`fullPage: true`) at **both** viewports so nothing below the fold is cut off, but first hide rack-mini-profiler's `.profiler-results` badge — dev-only chrome that reports *this request's* timing, so leaving it in makes every before/after pair differ on a number no reviewer cares about. It's injected after load, so run this after each navigation and again immediately before the shot:

```js
browser_evaluate: () => {
  document.querySelector('.profiler-results')?.style.setProperty('display', 'none');
  return document.body.scrollHeight; // content height with the chrome gone
}
```

If the returned content height is **less than the viewport height**, `browser_resize` the height down to it before the shot (the background fills the gap otherwise), then resize back to the standard viewport before the next URL. Taller-than-viewport pages need no resize — `fullPage` scroll-stitches them.

**Viewport-only is the caller's call, never yours — except when the diff's subject is a `position: fixed` or `sticky` element.** `fullPage` paints it once, where it sits at scroll 0, and nowhere else. Capture those at `fullPage: false`, scrolled to where the element pins. When the caller asks for it — "viewport only", "above the fold", "just the mobile viewport" — drop `fullPage` for the size they named and leave the other one full page.

**Settle before the screenshot.** Stimulus + Chartkick render after document load; either `browser_wait_for` on a known element or pause ~500ms–1s. Otherwise charts capture mid-draw. **`loading="lazy"` images capture blank below the fold** — `fullPage` stitching never scrolls them into view. Set `loading = 'eager'` on them and wait for every `naturalWidth` before the shot.

**Mid-interaction states are in scope.** When the caller asks for a dropdown open, a modal showing, a hover state, a partially-filled form, etc., drive Playwright between settle and the screenshot — `browser_click`, `browser_type`, `browser_press_key`, `browser_hover`, then wait for the UI to reach the target state (`browser_wait_for` on a marker element, or check via `browser_evaluate`) before `browser_take_screenshot`. Treat the interaction sequence as part of the page-slug — e.g. capture `settings-modal-open` after clicking, distinct from a static page-load shot. For cross-branch comparisons, run the *same* interaction sequence on each branch so the screenshots actually compare like-for-like.

**A loading state is captured by holding the request open, not by racing it.** In `browser_run_code_unsafe`, `page.route` the URL and delay with `await page.waitForTimeout(90000)` before `route.continue()` — `setTimeout` isn't defined there — then trigger the fetch.

**`localStorage` survives the base-branch checkout, and a mid-capture interaction writes to it.** The theme toggle persists `theme` and the unit toggle persists `unitPreference`, so a base loop run after a branch loop that toggled either renders differently at the same URL. Clear those keys, or re-apply the interaction, at the start of each loop rather than once per run.

**Being signed in is that same drifting state, and it reaches every page.** A run that captures public pages signed out and then signs in for an admin page leaves the session behind for whatever it captures next — so the base loop's public pages come back with a signed-in user dropdown against a signed-out branch shot, and the pair differs on chrome the PR never touched. Capture each loop's pages in the same order.

**An element missing from the shot may be a stale asset build, not the code.** `bin/dev`'s Tailwind watcher can miss a change, so a class is absent from what the server serves while the specs — whose builds you regenerated — pass. Confirm with `getComputedStyle` on the element, then run `bin/rails tailwindcss:build`; this needs no `bin/dev` restart.

Sanity-check each PNG: under ~5 KB usually means the page errored. Pull `browser_console_messages` and look only for **uncaught exceptions from app code** (Stimulus registration failures, `TypeError`s in `app/javascript/**`) — asset 404s and third-party deprecation warnings are noise. To diagnose a failed capture: HTTP status via `curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL/<path>"`, response body via `curl -s "$BASE_URL/<path>" | head -200`, full backtrace via `tail -200 log/development.log`.

## Component previews (when no page shows the state)

Some components only render in a context you can't reproduce on a normal dev page — a hard-to-reach error/empty state, or data the dev DB lacks. When a component has a ViewComponent/Lookbook preview (`app/components/**/component_preview.rb`), screenshot the **preview URL** instead of hunting for a page that happens to render it:

```
$BASE_URL/rails/view_components/<preview_path>/<scenario>
```

`<preview_path>` is the preview class underscored with the `Preview` suffix dropped, and `<scenario>` is the preview method. `Form::Group::ComponentPreview#text_field` → `/rails/view_components/form/group/component/text_field`. If a scenario doesn't exist yet, add a method to the component's `component_preview.rb` first — a preview that renders the exact state (pass the args that trigger it) is often the fastest path to a clean shot.

Use this bare route, not Lookbook's `/lookbook/inspect/...`, which wraps the component in its own browser chrome. `/lookbook/preview/...` is the one route that puts a whole `@!group` on a single page — `/lookbook/preview/form/group/kinds` for `Form::Group::ComponentPreview`'s `# @!group Kinds`. Reach for it when the shot needs several scenarios side by side. **It takes a group, not a scenario, and drops the trailing `component`** — `/lookbook/preview/form/group/component/kinds` and `/lookbook/preview/form/group/<scenario>` both 404, which reads as an unregistered group rather than a wrong path. On a dev server that's been up a while, the group page can stop picking up newly added scenarios — `bin/rails restart` clears it.

The preview page renders the component standalone in `layouts/component_preview` (no site chrome), so a preview that fits the viewport captures at `fullPage: false`. **A preview taller than the viewport still captures `fullPage: true`** — cropping out the changed part is the one thing the shot exists to show. Measure before choosing:

```js
() => document.querySelector('<selector for what changed>').getBoundingClientRect().top + window.scrollY
```

Everything else still applies — same PII/seed-data gate, same `(url-path, page-slug)` naming. Previews that query the dev DB render nothing when that data is missing — seed first with `bundle exec rails db:seed`. This is component-only: a preview can't show layout/stacking against the rest of the page, so use a real page for those.

## Cross-branch comparison (optional)

When the caller wants before/after, repeat the capture loop against the base ref. The caller passes the base — `origin/main` by default, or the PR's actual base when it isn't `main` (a stacked PR's base often isn't). Set `BASE_REF` to that remote ref (e.g. `origin/main`, `origin/sethherr/feature-x`) and use it throughout; `git fetch origin` first so it's current.

**Capture the base at what the branch actually merged, not at the ref's tip.** A fetch moves `origin/main` to commits the branch hasn't taken, so a base capture there renders *the base's newer work* and the diff attributes it to this PR. Check `git rev-list --count HEAD..$BASE_REF` before detaching: non-zero means merge first, or detach at `$(git merge-base HEAD $BASE_REF)` instead.

**The detached checkout in step 4 is a sanctioned exception to "never change branch" — don't stop and ask for it.** It detaches at a *remote* ref, reads, and returns to the same branch within this section, committing nothing. Nothing here licenses any other checkout, `git checkout -b`, or one that outlives the capture.

1. `git status` — abort if there are uncommitted changes.
2. Settle what you're detaching at, per the note above — `$BASE_REF`, or `$(git merge-base HEAD $BASE_REF)` when the branch is behind it. Call that `$BASE_AT`.
3. Diff `db/migrate/` between the branch and **`$BASE_AT`**, not `$BASE_REF`; abort if it changed — a branch-only migration leaves the DB schema ahead of the base's code, so base pages can error. **Don't abort on a migration that only adds a table, or a column with a default** — nothing on the base reads either, so load the target page after detaching and abort only if it errors.
4. `BRANCH=$(git rev-parse --abbrev-ref HEAD)`, `git checkout --detach $BASE_AT` (detached — checking out a branch name fails if a sibling worktree holds it; detached HEAD is allowed concurrently and is the same code), navigate the browser to force Rails to reload the changed files — the watcher can lag that first request, so confirm the page shows the base's markup (the changed element gone) and re-navigate if it doesn't — repeat capture into `...-base-...` filenames, then `git checkout $BRANCH`. Run `bin/rails tailwindcss:build` after each checkout — the watcher doesn't rebuild on a checkout, so a capture can render the other side's CSS.

A `Gemfile.lock` diff is **not** a reason to abort — but when it moves a gem the page loads (hotwire_combobox's JS and CSS), run `bundle install` and `bin/rails restart` after each checkout, or the base renders the branch's gem.

**Don't call a pair identical with `cmp`.** Two captures of the *same* code routinely differ by a few dozen bytes, so byte-equality reports a change that isn't one (and its absence proves nothing). Compare pixels, and establish the noise floor before reading anything into a number — recapture one page without changing branches, and treat that count as zero:

```bash
magick compare -metric AE <base>.png <branch>.png null:   # differing pixel count
magick compare <base>.png <branch>.png -compose src d.png && magick identify -format '%@' d.png   # where they differ
```

The bounding box is what settles it: dev-only chrome that slipped past the hide step lands in one small box, a real change doesn't.

The seeded DB persists across checkouts, so the existing session usually still works. Preview routes (`/rails/view_components/...`, `/lookbook/...`) reload across the checkout like ordinary pages, so their before/after works against any `$BASE_REF` too.

## Clean up

Once every screenshot is captured, quit Chrome with `browser_close` — including when the capture failed partway. Leaving it running holds the shared browser profile lock, so the next `browser_navigate` (this skill or another) fails with "Browser is already in use".

**Who closes is decided by who invoked you, so you never have to be told.** Invoked by the user — "grab a screenshot of X" — you're the last one in the browser: close it. Invoked by a workflow that captures again straight afterwards — the `pr` screenshot phase, which captures the base next — leave it open; closing between the two just pays the startup again.
