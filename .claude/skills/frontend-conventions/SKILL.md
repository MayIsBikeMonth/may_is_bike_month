---
name: frontend-conventions
description: >-
  May is Bike Month frontend conventions — the `twinput`/`twlabel`/`twlink`
  classes, dark mode, the `number_display` helper for numbers (not years),
  `UI::Time::Component` for time, the UI component library rule (every new
  button is `UI::Button`/`UI::ButtonLink`, every form field goes through
  `Form::Group`, every chart is `UI::Chart`, existing components before new
  ones, never a new `UI::*` argument without the user's permission), that
  **helpers are deprecated — render a view component taking full keyword
  arguments instead**, the collapse helpers for show/hide, and ViewComponent
  rules (when to write a partial instead, keyword arguments, instance
  variables, `helpers.` prefix in templates). Trigger when adding or
  modifying views (`.html.erb`), view components, Stimulus controllers,
  Tailwind classes, or any frontend code that touches styling or
  interactivity. **Also trigger before any
  `mcp__playwright__browser_take_screenshot` call** — this skill defines the
  required `tmp/` filename rule so screenshots don't land in the project
  root. Stimulus.js is the JavaScript framework.
---

# Frontend conventions

This project uses **Stimulus.js** for JavaScript interactivity and **Tailwind CSS** (v4, no class prefix) for styling. The `bin/dev` command handles building and updating Tailwind and JS.

**Format ERB before committing.** After editing any `.html.erb`, run `bin/lint` on the files or directories you changed — `bin/lint app/components/ui/table`. It runs `herb-lint` and `herb-format`, which reflow long `class` attributes and flag things like an `<input>` missing `autocomplete`. CI's `lint_and_scan` job runs `html:lint_check` separately from `standardrb`/`rubocop`, so hand-edited ERB that skips it fails CI even when the Ruby is clean. Scope it: a bare `bin/lint` reformats files you aren't working on.

## Tailwind classes and helpers

- Form fields use the `twinput` class, labels the `twlabel` class, basic links the `twlink` class.
- The default text color is `twtext-color`. It's an `@utility`, not a `@layer components` class — **any class that something `@apply`s has to be an `@utility`**; v4's `@apply` rejects a `@layer components` class with "Cannot apply unknown utility class".
- **`dark` is a custom variant keyed to a `.dark` ancestor** (`app/assets/tailwind/application.css`), which `theme_controller.js` sets on `<html>` from the user's theme setting (falling back to `prefers-color-scheme`). Write `dark:` variants alongside every color; check dark mode by switching the theme in the settings modal, or with `?lookbook[display][theme]=dark` on a preview.
- **A `@layer components` rule loses to a utility class on the same element**, whatever the specificity — so a hand-written rule that sets `display` is inert against an element carrying `grid` or `flex`, silently.
- **A Tailwind class a Stimulus controller toggles is a literal in that controller**, not a `static classes` value the template has to carry — `ui/table_controller.js` toggling `overflow-x-scroll` is the pattern. Tailwind scans `app/javascript`, so the utility is generated either way.
- **Every number** renders with `number_display(number)` — including one composed into a string: wrap the number, not the string.
  - "Number" includes counts, distances, elevation and quantities — anything whose magnitude is the point.
  - **Not a year.** `number_display` is `number_with_delimiter`, so it renders 2025 as "2,025". Emit a year bare, the way `Leaderboard::OtherCompetitionLinks` and `CompetitionHistory` do. The same applies to any identifier that only looks numeric.
- **Every date/time** renders through `UI::Time::Component` — `render(UI::Time::Component.new(time: some_time))`. It emits the client-localized `localizeTime` span the frontend JS converts to the viewer's timezone. Never `l(time, ...)`, `strftime`, `time_ago_in_words`, or a hand-written `localizeTime` span. Pass `format: :localize_time_precise` for seconds precision. It self-hides when `time` is nil, so no surrounding `if` guard is needed.

**Building markup to pass into a component argument uses `capture`** — a component keyword like `UI::Alert`'s `header:` or `UI::Header`'s `text:` takes a string, so a heading that wraps a link or an `<em>` has to be captured first.

## Tailwind v4 traps

- **A build that was right can go wrong under you.** Each workspace runs its own `tailwindcss:watch`, and one can overwrite `app/assets/builds/tailwind.css` with a scan from before your edit — so a rule you just wrote is served, then isn't. Before believing a CSS change doesn't work, count it in the build (`grep -o '<class>' app/assets/builds/tailwind.css | wc -l`) and check the built file's mtime against the source's. `bin/rails tailwindcss:build` restores it.
- **An `_` inside an arbitrary value compiles to a space.** `group-has-[#some_id:checked]:flex` builds `#some id:checked`, a descendant selector that never matches, so the class is emitted and inert. Use dashes in an id an arbitrary variant keys on, or escape it as `\_`.
- **A grid item stretches to its row.** For a `<div>` that's invisible, but a bare `<table>` grid item spreads the extra height across its own rows. `items-start` on the grid, or wrap the table in a `<div>`.

## Buttons: always `UI::Button` (and the UI component library generally)

**Every new button goes through `UI::Button::Component`** — never a hand-rolled `<button>` or submit input with ad-hoc Tailwind classes. The component centralizes colors (its `COLORS` is the list of record), sizes (`:sm`/`:md`/`:lg`), and the focus/active/dark-mode states; a hand-styled button silently drifts from all of that the next time the design changes. Older hand-rolled buttons exist — convert one when you touch it.

- Plain button or form submit — **a form submits with `color: :primary`**: `render UI::Button::Component.new(text: "Save", color: :primary, kind: :submit)`. Pass a class as `html_class:`.
- A link styled as a button: `UI::ButtonLink::Component.new(href:, text:, color:, size:)` — same palette, renders an `<a>`.

The same instinct applies beyond buttons: **check `app/components/ui/` and `app/components/form/` before hand-rolling any UI primitive** (dropdowns → `UI::Dropdown`, tooltips → `UI::Tooltip`, modals → `UI::Modal`, label-beside-value lists → `UI::DefinitionList`, badges, alerts, cards, pagination, tables…). If a component exists for the pattern, use it. **Never add an argument to a `UI::*` component without the user's explicit permission** — its arguments are the design system's surface, and one added for a single caller stays for every caller. If it almost fits, ask, and don't fork its markup inline meanwhile.

- **A form field gets its label from `Form::Group::Component`** — pass `form_builder:` and `attribute:`; never a bare `<label>` beside a hand-styled input.
- **Every chart goes through `UI::Chart::Component`** — not a bare chartkick helper.

## Showing and hiding elements: always use the collapse helpers

Any time you show, hide, or toggle an element in response to interaction, go through the shared collapse helpers. **Never** hand-roll it with the `hidden` attribute, `element.style.display`, `element.hidden = true`, or ad-hoc `classList.add('hidden')` — those skip the shared show/hide animation and the `hidden!`/`hidden` class contract.

- **Markup-only toggle**: add `data-controller="collapse"`, mark the collapsible element `data-collapse-target="content"`, and wire the trigger to `collapse#toggle` (or `show`/`hide`) — `app/javascript/controllers/collapse_controller.js`.
- **Inside your own Stimulus controller** (you have extra logic): import `collapse_utils` and call it directly:

  ```js
  import { collapse } from 'utils/collapse_utils'
  // ...
  collapse('show', this.formTarget)   // 'show' | 'hide' | 'toggle'; optional duration (default 200)
  ```

The collapsible element starts hidden with the **`hidden` class** (not the `hidden` attribute). Use **`hidden!`** when the element also carries a display utility that sorts after `hidden` — any `inline-*`, which every `UI::Button` has. A plain `hidden` renders that panel open, and no component spec can see it: the class is in the attribute, it just loses the cascade. Component specs assert the initial state by class, not Capybara visibility — the rack_test driver doesn't evaluate CSS.

## No dead hooks in markup

Only add an `id` or non-utility `class` when something concrete consumes it — a CSS rule, a JS/Stimulus selector, a test fixture, an accessibility attribute. Don't keep or invent "structural identifier" hooks "in case something needs them later."

When deleting an `id`/`class`, grep the repo for the name first:

- Zero consumers: delete it, don't rename it.
- Consumers exist: either update them, or leave the hook in place — the consumers are the *reason* it earns its spot in the markup.

## Helpers are deprecated — render a view component instead

**Never add a helper method, and don't extend an existing one.** Anything a helper would render belongs in a view component that takes what it needs as explicit keyword arguments. `app/helpers/application_helper.rb` is legacy: leave what's there, but move a helper into a component when you touch the line that calls it.

- A *view helper* that only gathers a component's arguments out of controller assigns is still a helper — pass those arguments from the view.
- `ApplicationComponentHelper` is the exception (`number_display`, `check_mark`, `cross_mark`, `strava_link`) — value formatters `ApplicationComponent` already includes, so components call them bare.

## ViewComponent rules

This project uses the ViewComponent gem to render components, with Lookbook at `/lookbook`.

- **Prefer an existing component to a new one, extended if needed.** Before creating one, look for a component that already renders the pattern or its core. A new component whose template is mostly one existing `UI::*` component plus chrome is that component with an argument: ask to extend it (the no-new-argument rule above) rather than wrapping it to avoid asking.
- **Before creating a component, check it earns its class.** If its `component.rb` would hold nothing but `initialize` assigning arguments to ivars, and fewer than 3 callers render it, write a partial instead, with `<%# locals: (…) %>` at the top — `admin/competition_users/_table.html.erb` is the pattern. A component earns its class with logic to name, a cache key to build, or a third caller; past that bar, prefer components to partials.
- **If a view file only renders a single component, consider rendering it from the controller instead** (`render Foo::Component.new(...)`) and deleting the view file — the layout still wraps it.
- Generate a new view component with `rails generate component ComponentName argument1 argument2`.
- View components must initialize with **keyword arguments**. Everything the component needs must be passed in explicitly by the caller — never reach into controller state from inside a component (e.g. `controller.instance_variable_get(:@user)`). If the component needs `@user`, the caller renders `Component.new(user: @user)`.
- In view components, use instance variables directly — don't add `attr_reader`/`attr_accessor`. Reference `@foo` everywhere, including in the template.
- In ViewComponent templates, use the `helpers.` prefix for view helpers (e.g. `helpers.time_ago_in_words`) — a legacy bridge, and a sign the helper wants to be a component.
  - Rule of thumb: try the bare call first. Only add `helpers.` if it fails with `NoMethodError` — route helpers (`competition_path`) and ActionView tag/url builders (`tag.span`, `content_tag`, `link_to`) are mixed into `ViewComponent::Base` directly, so they don't need it.
- **Never nest a component inside a folder that already holds a `component.rb`.** Each component lives in `app/components/<path>/component.rb` (and `spec/components/<path>/component_spec.rb`); siblings go in sibling folders, not subfolders — `leaderboard/punchcard_user_row/`, not `leaderboard/punchcard/user_row/`.
- **Change a component's signature, then open its `component_preview.rb`** — nothing renders every preview in the suite, so a stale one raises `ArgumentError: unknown keyword` on its Lookbook page with the whole suite green. `curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/rails/view_components/<path>/component/<scenario>"` is the check.
- **Cache rows, never cells.** Pass `cache_key:` to `UI::Table::Component`, which caches each row on `[cache_key, record]`, rather than putting a `cache(...)` inside a column block.
- **Moving a view into a component turns its locals into methods.** A `<% x = … %>` computed once per template becomes a method run once per *call site* — which is how a single pluck becomes one per table row. Memoize anything that queries as you move it.
- **Converting a partial to a component is a faithful move, not a cleanup.** Carry the markup over verbatim, including comments and commented-out code: those are often a deliberate stash. The only changes a conversion introduces are the ones the move requires — adding `helpers.` where a helper now needs it. Dead code worth removing goes in its own commit.

## Manual browser verification

**Every `mcp__playwright__browser_take_screenshot` call must pass a `filename:` that starts with `tmp/`** (e.g. `tmp/tooltip-ride-day.png`). The MCP tool's default root is the project root — a bare filename like `tooltip.png` lands in the working tree, shows up in `git status`, and has to be cleaned up by hand. `tmp/` is gitignored, so screenshots there stay out of commits. This applies to ad-hoc visual verification; PR screenshots are the `frontend-screenshots` skill's.
