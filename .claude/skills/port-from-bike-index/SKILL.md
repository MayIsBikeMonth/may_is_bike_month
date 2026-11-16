---
name: port-from-bike-index
description: >-
  How to port skills, UI components, or other shared code from the upstream
  `bikeindex/bike_index` repo into May is Bike Month. The two repos share a
  design-system and agent-skill lineage but have **forked**, so a verbatim copy
  breaks things — this skill covers the fork axes (the `tw:` Tailwind prefix,
  `translation()`/`.en.yml` i18n, and domain/infra
  divergence), how to fetch and diff bike_index's files, and the
  per-file decision procedure for what to port, adapt, or skip. **Use this
  whenever the user asks to port / pull / sync / bring over / update anything
  from bike_index** — "pull in updates from bike_index", "sync our components
  with bike_index", "copy the X skill from bike_index", "grab bike_index's Y" —
  even if they don't mention the fork gotchas. Also use it when reconciling a
  component, hook, or skill that came from bike_index and now breaks here.
---

# Porting from bikeindex/bike_index

`bikeindex/bike_index` is upstream for the shared **UI component library** (`app/components/ui/**`), the **agent skills and hooks** (`.claude/**`), and the **workspace scripts** (`bin/setup`, `bin/env`, `bin/lint`, `bin/workspace_*`). May is Bike Month (MIBM) tracks it, but the two have **diverged**, so the job is never "copy the file" — it's "bring bike_index's version over, *adapted* to MIBM."

**Default posture: prefer bike_index.** When the two genuinely differ, **adopt bike_index's version** — even if MIBM's looks richer, even if upstream *dropped* a feature, even if the change looks lateral. "MIBM's is ahead" is not a reason to keep it; the goal is to track upstream. The only reasons to deviate are mechanical, and they're about *how you adapt*, never about rejecting:

- **The fork axes** (below) — you still adopt upstream's *change*, spelled in MIBM's dialect.
- **A missing model** (Step 3): the component is blocklisted. Any other missing dependency gets ported with the component, or raised with the user if it's a whole subsystem. Neither is a reason to quietly keep MIBM's version.

If you think there's a third reason, you're probably rationalizing — **ask the user**. (An MIBM-only feature upstream lacks is fine to keep as an *additive extension on top of* upstream's version, never instead of it.)

A naive `cp` looks like it works — lint passes, the file renders — and then silently breaks styling or a live page. The checks below catch that.

## The fork axes

1. **Tailwind prefix.** bike_index prefixes every utility with `tw:` (`tw:flex tw:dark:bg-gray-800`); MIBM's `app/assets/tailwind/application.css` imports Tailwind unprefixed. A copied `tw:` class renders unstyled while lint stays green, so stripping `tw:` is the first transform on any markup.

   **The prefix renames Tailwind's theme variables too.** Upstream's `var(--tw-spacing)` is `var(--spacing)` here; a `tw:` strip leaves `--tw-` intact (it isn't followed by a colon), and the browser silently discards the invalid `calc()`. Grep everything ported — CSS *and* arbitrary values in Ruby/ERB like `shadow-[4px_4px_0_var(--tw-color-gray-300)]` — for `var(--tw-`, and check the **built** file (`grep -c -- '--tw-spacing:' app/assets/builds/tailwind.css` → expect 0) rather than reading the source back.

2. **i18n.** bike_index localizes components with `translation(".key")` backed by a `component.en.yml` sidecar. MIBM has neither — inline the English string at each call site (read the sidecar's value first) and drop the sidecar.

3. **Namespaces are not a fork axis.** Component names and paths match upstream's exactly — `UI::Forms::*`, `UI::Alerts::*`, `UI::Table::*`, `UI::DefinitionList::*`. When upstream moves or renames a `UI::` component, follow it and migrate every MIBM caller. Upstream's `Atoms::` (`app/components/atoms/`) and every other non-`UI` namespace is out of scope — a component moving from `UI::` into `Atoms::` is leaving the tracked surface, not a rename to follow.

4. **Domain & infra.** bike_index is bikes / orgs / marketplace with password sign-in; MIBM is users / competitions / Strava activities with **Strava-OAuth-only** sign-in. Translate:
   - `BikeIndexFormBuilder` → `MayIsBikeMonthFormBuilder`
   - bike/org examples in prose and previews → competitions, users, activities
   - `bikeindex.org` seed users and `/session/new` sign-in → MIBM's seeded display names (`frontend-screenshots`); there's no scriptable sign-in here
   - upstream's root `AGENTS.md` → MIBM's **`agents.md`** (lowercase; `claude.md` symlinks to it). Don't rename either.
   - **Turbo drive:** upstream sets `Turbo.session.drive = false`; MIBM leaves drive on. Upstream guidance or specs that assume a link click is a full page load (or that add `data-turbo="true"` as an opt-in) need rethinking — in a system spec here, clicking an `href="#"` link is a Turbo visit that detaches held elements.
   - **System specs** run through upstream's capybara-playwright-driver setup (`spec/support/capybara.rb`, `spec/support/axe.rb`), with MIBM's jsdelivr routing added in `spec/support/local_chrome.rb`. MIBM's `.rspec` doesn't exclude `:js`.

   Things MIBM *does* share port straight across: `helpers.sortable_search_params`, `number_display`, `UI::Time`, `/simplify`, `herb-format` via `bin/lint`, `collapse_controller` + `utils/collapse_utils.js`, `hotwire_combobox`, VCR. bike_index-only infra — SCSS/CoffeeScript, `AddressRecord`, `ShortIdable`, `ComponentStructs`, Doorkeeper, the `AdminData` API, `bin/binx_hb`, multi-database/`acts_as_paranoid` notes — means adapt, port the dependency too, or skip.

## Step 1 — Fetch bike_index's files

Shallow sparse clone, only the trees you need:

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/bikeindex/bike_index.git /tmp/binx_clone
cd /tmp/binx_clone
git sparse-checkout set .claude app/components/ui app/javascript spec/components bin
git sparse-checkout add AGENTS.md .herb.yml .rspec package.json --skip-checks   # files need --skip-checks
```

The shared surface is wider than components and skills: Stimulus controllers and `app/javascript/utils/**`, `app/assets/tailwind/**`, view helpers, `spec/support/**`, `.claude/hooks` + `.claude/settings.json`, `bin/` workspace scripts, and root files. Add whatever the task touches.

**Always pull and diff `spec/components/**` alongside a component** — upstream ships spec changes with the component (new cases, assertions on new design tokens). A component isn't ported until its `*_spec.rb` and `*_system_spec.rb` are reconciled in the same pass; otherwise a spec keeps asserting the old markup. Preview URLs port straight across — MIBM serves both Lookbook (`/lookbook`) and ViewComponent's native `/rails/view_components/...`; `curl` the referenced scenario and expect a 200 with component markup.

**Also diff the shared JS tree** (`app/javascript/controllers/**`, `app/javascript/utils/**`) whenever a sync touches components — it drifts often and the default fetch misses it. `utils/collapse_utils.js` drives every show/hide here; adopt upstream's (strip `tw:` from its class literals first). Upstream's `utils/hw_combobox_patch.js` monkeypatches a GitHub revision of the `hotwire_combobox` gem, so when upstream bumps its `Gemfile.lock` ref, bump MIBM's `Gemfile` pin to match in the same change.

**Also diff `.herb.yml`** — its `version:` and rule names track the **npm** `@herb-tools/*` packages, so pull `package.json` in the same pass and bump the pin before adopting rules the installed linter doesn't know. Keep MIBM's excludes; drop upstream's for absent trees (`kelsey_redesign/**`, `**/*.coffee.erb`). Don't copy the disabled-rules list blind — probe with an empty `rules:` and `npx herb-lint --format=simple`, and disable only what MIBM actually trips. Adopt rewriters (e.g. `tailwind-class-sorter`) and run `npx herb-format .` in the same commit so the mechanical reorder lands with the config.

**Also diff the agent-instruction file:** `git diff --no-index agents.md /tmp/binx_clone/AGENTS.md`. Most of it is fork-axis, but app-agnostic rules do land there — treat a rule as portable unless it names infra MIBM lacks.

**A same-named file isn't necessarily the same thing.** A diff that replaces a small file wholesale is the tell: read both and ask whether they solve the same problem. MIBM's `auto_submit_controller.js`, for one, submits on a combobox selection — an upstream controller with that name doing something else would silently break it.

**Whatever you port, grep it for what it *assumes exists*** — a root config file, a CSS class, a Stimulus controller, a helper, a hook script, an env var `bin/env` sets — and confirm MIBM has each. A `data-controller="x"` with no `x_controller.js` raises nothing; Stimulus just never connects:

```bash
grep -rhoE 'data-controller="[^"]+"' app | grep -oE '"[^"]+"' | tr -d '"' | tr ' ' '\n' | sort -u
find app/javascript/controllers -name '*_controller.js'
```

## Step 2 — See the *real* diff

Raw diffs drown in `tw:`. Build a stripped mirror and diff that — strip `tw\\:` (escaped, as spec CSS selectors write it: `have_css("div.tw\\:flex-wrap")`) **before** `tw:`, or the backslash survives:

```bash
STRIP=/tmp/binx_stripped; rm -rf "$STRIP"; cp -R /tmp/binx_clone/app/components/ui "$STRIP"
find "$STRIP" -type f -exec ruby -e 'ARGV.each { |f| s = File.read(f); File.write(f, s.gsub("tw\\\\:", "").gsub("tw:", "")) }' {} +
grep -rn 'tw:\|tw\\' "$STRIP"   # expect nothing
git --no-pager diff --no-index --stat app/components/ui "$STRIP"
```

Files absent from the diff already match. Skills and hooks need no strip.

**Compare both directions.** Looping over MIBM's files can only report files MIBM already has — every new upstream file is invisible and the run looks clean:

```bash
comm -13 <(cd app/javascript && find . -type f | sort) <(cd /tmp/binx_clone/app/javascript && find . -type f | sort)  # upstream-only
comm -23 ...  # MIBM-only: leave alone, never delete
```

Grep each upstream-only controller identifier across `app spec`. **Zero hits is a finding, not a pass** — the producer is usually a component change in the same upstream commit, so grep *upstream* for what emits it.

**Read which direction a diff goes.** After a sync, most remaining diffs on shared files are MIBM's adapted copies vs upstream's originals — upstream "adding" `tw:`, `translation()`, or bike examples. Re-porting that regresses MIBM. Upstream adding genuinely new prose or behavior: adopt it.

**After the first sync, diff upstream against itself.** Record the upstream SHA you synced to in the commit message; next time, `git -C /tmp/binx_clone diff --stat <last-sha> HEAD -- <trees>` isolates exactly what's new with no fork-axis noise (`git fetch --unshallow --filter=blob:none` if the shallow clone lacks it). With no recorded SHA, pick a candidate by the date of MIBM's last sync and bucket files: MIBM == candidate and candidate != HEAD → port; MIBM != candidate and candidate != HEAD → merge; candidate == HEAD → already decided.

## Step 3 — Decide per file: port, adapt, or skip

**Every upstream `UI::` component ports, except one that needs a model MIBM doesn't have.** That includes upstream-only ones nothing here renders yet. Don't pick which to pull; keep the blocklist of model-dependent components instead, each naming the model it needs:

- **`UI::AddressDisplay`**: `AddressRecord`
- **`UI::Forms::AddressGroup`**: `Country`
- **`UI::Forms::ComboboxManufacturer`** and **`ComboboxManufacturerOptions`**: `Manufacturer`, `BParam`
- **`UI::Forms::ComboboxState`** (and its controller): `State`, `StatesAndCountries`
- **`UI::Forms::LegacyFormWell`**: `AddressRecord`, `Country`, `State`, `Bike`

And these, by the user's call rather than a missing model:

- **`UI::Forms::TextEditor`**: the Lexxy rich-text editor and Action Text
- **`UI::Forms::Turnstile`** (and its controller): a Cloudflare Turnstile integration
- **`UI::Forms::NestedFields`** (and its controller): needs an `accepts_nested_attributes_for` association, which no model here declares

Check what a component's `component.rb`/`.html.erb` calls, not its preview. A preview that queries an absent model (`UI::Chart`'s `Bike` preview, for example) gets static data, and the component still ports. Only a model counts, and only when the component needs its records: a constant on an absent model comes over on its own (`UI::Forms::Email` brings `EmailDomain::RESERVED_REGEX`, `UI::ColorSwatch` brings `Color`'s two cover-up constants, each as a plain module). A missing helper, service or gem gets ported along with the component: `GraphingHelper` for `UI::Chart`, and `BlobUrl` for `UI::Forms::Files` with its CarrierWave branch dropped. The exception is a dependency the size of a subsystem. Ask about that one, and add it to the list above if the answer is to skip. When upstream adds a component that needs an absent model, add it to this list and tell the user.

Per file:

- **Port (transform-only):** references nothing from axis 4. Apply the transforms, done.
- **Adapt:** portable idea, absent references — rewrite them to MIBM's equivalents. Only when a real equivalent exists.
- **Port the missing piece too:** before writing anything off, weigh the gap. A couple of constants or one small method? Bring it over and port the component. A model capability (e.g. `accepts_nested_attributes_for` for `NestedFields`) is a bigger step — fine, but say so in the PR.
- **Measure an MIBM-only feature before preserving it.** Before forking a component to keep an MIBM kwarg upstream dropped, prove the kwarg still does something — render the page in a request spec and diff the markup, or drive it in a system spec. A capability that no longer does anything isn't a reason to diverge, and reading the code won't tell you which is which.
- **Import the real implementation, never a shim.** "Import X" means upstream's actual X — all its variants and params — not MIBM's simpler version renamed. Re-add an MIBM-only feature as an additive extension on top. Follow the dependency chain (a rendered sub-component, new arbitrary Tailwind classes → rebuild Tailwind).
- **Skip → ask first.** Only when closing the gap means importing a whole subsystem. Name what's missing and ask whether to skip or port the dependency.

**Never** delete MIBM-only files, and **never** overwrite an MIBM skill section that's deliberately adapted to MIBM (Strava-only sign-in, MIBM's DB names and seeds). Still diff every shared skill every sync — this only decides what you do with the result.

### Porting components — the signature audit is mandatory

An exact port compiles, lints, and passes its own spec — but component specs render the component directly and **don't exercise callers**. A keyword upstream renamed or dropped surfaces only as an `ArgumentError` on a live page. For each ported component, diff `def initialize` and grep callers for every removed keyword:

```bash
for c in alert badge button card dropdown table time tooltip; do
  f="app/components/ui/$c/component.rb"
  echo "### $c"; echo "  HEAD: $(git show HEAD:"$f" | grep -m1 'def initialize')"; echo "  PORT: $(grep -m1 'def initialize' "$f")"
done
grep -rn "<removed_kwarg>:" app
```

- **Added/unchanged keywords** → fine.
- **Removed keyword a real caller uses** → prefer (a) adopt upstream and push the concern to the call site (layout like width/margin belongs on a wrapper), then (b) adopt upstream and re-add the feature as an extension. If neither fits, ask. Never just keep MIBM's version.
- **Removed keyword only a preview/spec uses** → not a caller. Drop it and update the preview and spec.

Handle **paired** components together (`table` ↔ `table_column`; `definition_list` container ↔ row).

**An addition can break MIBM too.** A new validation or warning can reject MIBM's own seeds or factories — check new rules against `db/seeds.rb` and `spec/factories`, not just the component spec. When a shared rule collides with a local convention, prefer moving MIBM to the convention over narrowing the rule.

**A restyle arrives as a family.** A palette retune lands across every component sharing those constants *and* the CSS custom variants and `tw*` rules they rely on. Port the family and its CSS together, and update specs asserting old tokens to the new ones — don't loosen them.

### Porting skills, hooks, and scripts

Skills are prose: port **app-agnostic improvements**, and confirm MIBM has the infra each piece of guidance names. Rewrite bike-domain examples to MIBM's, and drop guidance about absent infra (SCSS/CoffeeScript, `translation()` sidecars, `.haml`, `MARKUP_DIGEST`, the `tw:` rule). Keep MIBM's richer sections over a thinner upstream rewrite.

- **`sandbox-test-setup`: diff, then cherry-pick.** MIBM's DB names, seeds, and env differ, so don't overwrite — but version numbers, paths, and tool names go stale silently and port cleanly.
- **Keep upstream's `references/` split.** SKILL.md loads in full every time; a reference loads only when a step sends you there. Adopting the prose but keeping it inline doubles what every invocation pays.
- **Hooks and `bin/` scripts:** MIBM's `bin/` scripts are snake_case with no extension; check every path and env var a hook names exists here.
- **Production-triage skills** (`admin-data-api`, `honeybadger-debugging`, `production-log-inspection`) depend on bike_index's `AdminData` API, `bin/binx_hb` and its log host — skip unless MIBM grows the equivalent.

**Track what you leave out.** A skipped skill, a dropped section, a kept-MIBM bit — each gets a row in `references/inventory.md`. Prose omissions are invisible in a diff. "Not evaluated this pass" isn't a reason — if it's app-agnostic, port it.

## Step 4 — Verify

A sync touches shared code wholesale, so verify the whole ported surface, not just one file:

1. `bin/lint <ported trees>` — must be clean.
2. `bundle exec rspec spec/components` — green doesn't prove callers are safe (that's the signature audit), so also run the request/system specs for pages that render ported components.
3. Render-check in isolation: `bin/rails runner 'puts UI::Badge::Component.new(text: "x").render_in(ActionController::Base.new.view_context)'`.
4. Ported JS: confirm the controller connects in a browser (`window.Stimulus.getControllerForElementAndIdentifier`), not just that the file exists.
5. Ported hooks/scripts: run them once in this workspace.

## What to hand back

State plainly what was **ported** (transformed how), **adapted**, **skipped** (name the missing model/helper) and **reverted** (name the caller it would have broken), with the inventory table from `references/inventory.md`. Report the verification you actually ran. The skips and reverts are the valuable part — they're why a blind copy would have shipped broken code.
