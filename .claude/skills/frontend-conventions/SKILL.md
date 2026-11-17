---
name: frontend-conventions
description: >-
  May is Bike Month frontend conventions — the `twinput`/`twlabel`/`twlink`
  classes, dark mode, the `number_display` helper for numbers (not years),
  `UI::Time::Component` for time, the UI component library rule (every new
  button is `UI::Button`/`UI::ButtonLink`, every form field goes through
  `UI::Forms::Group`, every typeahead is `UI::Forms::Combobox`, every FAQ is
  `UI::Accordion`, every chart is `UI::Chart`, existing components before new
  ones, never a new `UI::*` argument without the user's permission), that
  **helpers are deprecated — render a view component taking full keyword
  arguments instead**, the collapse helpers for show/hide, and ViewComponent
  rules (when to write a partial instead, keyword arguments, instance
  variables, `helpers.` prefix in templates). Trigger when adding or
  modifying views (`.html.erb`), view components, Stimulus controllers,
  Tailwind classes, image or icon files under `app/assets/images` (which
  usually already exist), or any frontend code that touches styling or
  interactivity. **Also trigger before any
  `mcp__playwright__browser_take_screenshot` call** — this skill defines the
  required `tmp/` filename rule so screenshots don't land in the project
  root. Stimulus.js is the JavaScript framework.
---

# Frontend conventions

This project uses **Stimulus.js** for JavaScript interactivity and **Tailwind CSS** (v4, no class prefix) for styling. The `bin/dev` command handles building and updating Tailwind and JS.

**Format ERB before committing.** After editing any `.html.erb`, run `bin/lint` on the files or directories you changed — `bin/lint app/components/ui/table`. It runs `herb-lint` and `herb-format`, which reflow long `class` attributes and flag things like an `<input>` missing `autocomplete`. CI's `lint_and_scan` job runs `html:lint_check` separately from `standardrb`/`rubocop`, so hand-edited ERB that skips it fails CI even when the Ruby is clean. Scope it: a bare `bin/lint` reformats files you aren't working on, and every one you've already read is re-injected into context in full.

## Tailwind classes and helpers

- Form fields use the `twinput` class, labels the `twlabel` class, basic links the `twlink` class.
- A link that should take the color of the text around it — inside an alert, a colored `<small>` — uses `twlink-underlined` instead. Never hand-roll `text-inherit underline`. Its color must come from an ancestor, not a `text-*` on the link itself, which would outrank the class at every state.
- **A row of two or three things side by side uses `twfieldrow` or `twwiderow`**, not `md:grid-cols-2`. `twfieldrow` is for fields that read as one control (a city and its state); `twwiderow` is for cards and sections, and `twwiderow twwiderow-3` for three of them. Both break on the row's own width rather than a viewport breakpoint, so a row nested in a narrow card breaks where it should. `UI::Card`'s `full_bleed:` is keyed to `twwiderow` by a container query, so it only bleeds inside one, and only once that row is single-column. All three are in `app/assets/tailwind/bike_index_components.css`.
- A small purple section label is `tweyebrow`.
- The default text color is `twtext-color` (`twtext-color!` to force it). It's an `@utility`, not a `@layer components` class — **any class that something `@apply`s has to be an `@utility`**; v4's `@apply` rejects a `@layer components` class with "Cannot apply unknown utility class".
- **A horizontal scroller runs out to its container's edges, the container's padding inside it** — `twgutter-bleed overflow-x-auto`, with `--gutter` set to that padding wherever it isn't the page's (`[--gutter:--spacing(2.5)]` in a `px-2.5` table cell). `UI::Table::Base` and `UI::Tabs` are the pattern; an `m-0` or `p-0` beside `twgutter-bleed` undoes it. A scroller that is its own bordered box — a code block — scrolls inside its border instead.
- **`dark` is a custom variant keyed to a `.dark` ancestor** (`app/assets/tailwind/application.css`), which `theme_controller.js` sets on `<html>` from the user's theme setting (falling back to `prefers-color-scheme`). Write `dark:` variants alongside every color; check dark mode by switching the theme in the settings modal, or with `?lookbook%5Bdisplay%5D%5Btheme%5D=dark` on the bare `/rails/view_components/` route, which `/lookbook/preview/` ignores. Black-ink art on a transparent background is `dark:invert dark:hue-rotate-180`.
- **A status surface in dark mode is a tint, not a solid `-950`** — the status color mixed 25% into `gray-900`, with a `/50` border. `UI::Alerts::Base` is the pattern.
- **A custom `@utility` has no fixed rank against a core one it collides with** — Tailwind sorts custom and core utilities together, so which wins depends on the pairing — `twfullbleed` emits before `border`, which is why its rules are all `!`. An unlayered rule outranks every layer, so it takes ties with no `!` — `.period-select-standard` in `application.css` is the pattern. Grep `app/assets/builds/tailwind.css` for the two selectors when a collision matters.
- **A `@layer components` rule loses to a utility class on the same element**, whatever the specificity — so a hand-written rule that sets `display` is inert against an element carrying `grid` or `flex`, silently. A variant utility has no such problem, and reaches further than it looks: `group`, `peer` and arbitrary variants can drive a whole state swap with no rule at all. Use `@custom-variant` when the state is worth naming for templates to use inline (`is-active` and `table-bleed` are the pattern), and a long selector written out per utility in a component constant, since Tailwind scans for whole class names.
- **A Tailwind class a Stimulus controller toggles is a literal in that controller**, not a `static classes` value the template has to carry — `ui/table_controller.js` toggling `overflow-x-scroll` is the pattern. Tailwind scans `app/javascript`, so the utility is generated either way; reach for `static classes` only when call sites need different classes.
- **Every number** renders with `number_display(number)` — including one composed into a string: wrap the number, not the string.
  - "Number" includes counts, distances, elevation and quantities — anything whose magnitude is the point.
  - **Not a year.** `number_display` is `number_with_delimiter`, so it renders 2025 as "2,025". Emit a year bare, the way `Leaderboard::OtherCompetitionLinks` and `CompetitionHistory` do. The same applies to any identifier that only looks numeric.
- **Every date/time** renders through `UI::Time::Component` — `render(UI::Time::Component.new(time: some_time))`. It emits the client-localized `localizeTime` span the frontend JS converts to the viewer's timezone. Never `l(time, ...)`, `strftime`, `time_ago_in_words`, or a hand-written `localizeTime` span. Pass `format: :localize_time_precise` for seconds precision. It self-hides when `time` is nil, so no surrounding `if` guard is needed.

- **Look for an existing icon before adding an SVG** — all of `app/assets/images/` (not just `icons/`), and text glyphs in templates. A mark that's a plain character is text, not an icon: a link's trailing arrow is `<span aria-hidden="true">→</span>`, and a `?`, `!` or `i` in a disc is the character (`UI::Tooltip`). A check or a cross stays an icon.
- **A decorative icon is `inline_svg_tag(..., aria_hidden: true)`** — `aria: {hidden: true}` is a hash `inline_svg` drops, leaving an `svg[role=img]` with no accessible name, which only an axe audit in a `:js` spec catches.

**Building markup to pass into a component argument uses `capture`** — a component keyword like `UI::Alerts::Base`'s `header:` or `UI::Header`'s `text:` takes a string, so a heading that wraps a link or an `<em>` has to be captured first.

## Tailwind v4 traps

- **A build that was right can go wrong under you.** Each workspace runs its own `tailwindcss:watch`, and one can overwrite `app/assets/builds/tailwind.css` with a scan from before your edit — so a rule you just wrote is served, then isn't. Before believing a CSS change doesn't work, count it in the build (`grep -o '<class>' app/assets/builds/tailwind.css | wc -l`) and check the built file's mtime against the source's. `bin/rails tailwindcss:build` restores it.
- **An `_` inside an arbitrary value compiles to a space.** `group-has-[#some_id:checked]:flex` builds `#some id:checked`, a descendant selector that never matches, so the class is emitted and inert. Use dashes in an id an arbitrary variant keys on, or escape it as `\_`.
- **A grid item stretches to its row.** For a `<div>` that's invisible, but a bare `<table>` grid item spreads the extra height across its own rows. `items-start` on the grid, or wrap the table in a `<div>`.

## Buttons: always `UI::Button` (and the UI component library generally)

**Every new button goes through `UI::Button::Component`** — never a hand-rolled `<button>`, `button_to`, or submit input with ad-hoc Tailwind classes. The component centralizes colors (its `COLORS` is the list of record), sizes (`:sm`/`:md`/`:lg`), and the focus/active/dark-mode states; a hand-styled button silently drifts from all of that the next time the design changes. Older hand-rolled buttons exist — convert one when you touch it.

**An in-page action trigger that doesn't navigate is a `UI::Button`, not `link_to "#"`** — with Turbo Drive on, clicking an `href="#"` link is a Turbo visit.

- Plain button or form submit — **a form submits with `color: :primary`**: `render UI::Button::Component.new(text: "Save", color: :primary, type: "submit")`. Pass a class as `html_class:` — the component builds its own, so a `class:` raises.
- A link styled as a button: `UI::ButtonLink::Component.new(href:, text:, color:, size:)` — same palette, renders an `<a>`.
- A standalone action button (POST/DELETE/etc. to a URL): pass `method:` to `ButtonLink` and it renders `button_to` for you (`render UI::ButtonLink::Component.new(text: "Delete", color: :error, href:, method: :delete)`), so don't hand-roll a `button_to` or wrap a submit button in a bare form. Pass `params:` for a POST that carries params — they render as hidden fields.

  - **Not inside another form** — `button_to` renders a `<form>`, and the parser drops a nested one, hoisting its button into the outer form, which that button then submits. Nothing errors; it just does the wrong thing when clicked. Either pass `confirm:` (below), or, for an action with no prompt, carry the verb on a link with `data: {turbo_method: :put}`.

- **An action that needs confirming passes `confirm:` alongside `method:`**, and the component renders a Turbo link rather than a `button_to` — an `<a>` carrying the method plus an `onclick` that Turbo's click handler honours. So a confirming action nests anywhere a link does.

The same instinct applies beyond buttons: **check `app/components/ui/` before hand-rolling any UI primitive** (dropdowns → `UI::Dropdown`, tooltips → `UI::Tooltip`, modals → `UI::Modal`, form fields → `UI::Forms::*`, label-beside-value lists → `UI::DefinitionList` or `UI::Table::List`, inline code → `UI::Code::Inline`, a block of JSON → `UI::Code::Json`, badges, alerts, cards, pagination, tables…). If a component exists for the pattern, use it. **Never add an argument to a `UI::*` component without the user's explicit permission** — its arguments are the design system's surface, and one added for a single caller stays for every caller. If it almost fits, ask, and don't fork its markup inline meanwhile.

Several carry a rule beyond "use the component":

- **`UI::Tooltip` keeps its default `?` button trigger** unless the user explicitly says otherwise — never pass a label as the trigger content.
- **A form field gets its label from `UI::Forms::Group::Component`** — pass `form_builder:` and `attribute:`, or render a `UI::Forms::*` field inside a `Group` block; never a bare `<label>` beside a hand-styled input. Holds for `Combobox`, `Select`, and `Files::Upload`, whose own `Upload` button is a second label for the same input and audits clean beside `Group`'s (`spec/components/ui/forms/group/component_system_spec.rb`). A visually hidden label is the exception: `Group`'s label carries a required/optional suffix, so use a bare `label_tag` with `twlabel sr-only`.
- **Every typeahead / autocomplete goes through `UI::Forms::Combobox::Component`** — never a new Stimulus controller that fetches matches and renders its own menu. `spec/components/ui/forms/combobox` shows how to invoke it.
- **Every FAQ / list of questions is `UI::Accordion::Component`** — `items:` as `[question, answer]` pairs. Never hand-rolled `<details>` or per-item `UI::Collapse` markup.
- **Every chart goes through `UI::Chart::Component`** — chartkick is pinned `preload: false` (`config/importmap.rb`) and loaded by the component's `ui--chart` controller, so a bare `column_chart`/`line_chart` call renders the placeholder and nothing else. Pass `kind:` for a line or pie.

## Current-page links: always `UI::ActiveLink`

**Every link that goes `aria-current` on the page it points at goes through `UI::ActiveLink::Component`** — never `current_page?` in a template, and never a Stimulus controller of your own comparing `window.location`. It derives the state in the browser (`app/javascript/controllers/ui/active_link_controller.js`), so there's no way to pass the answer in: `match_paths:` is the only control over what counts as the page it points at.

**`match_params:` is the params the entry stands for, not the ones its `path:` sets** — a filter entry that toggles links *away* from itself to clear the filter, so the two differ. Passing `path:`'s value to both fails silently, and only on the entry that is currently applied.

## Form drafts: always `form-persist`

**A form worth not retyping mirrors itself to localStorage through the `form-persist` controller** — never one of your own. It takes a `data-form-persist-key-value` when the derived key — the pathname plus the form's action — isn't unique per form. `ui/forms/combobox/component_preview/persisted.html.erb` is the pattern.

**A controller whose UI hangs off a restored field reconciles in two places** — a `form-persist:restored@window->…` entry in the element's `data-action`, and the same call in its own `connect`.

## Showing and hiding elements: always use the collapse helpers

Any time you show, hide, or toggle an element in response to interaction, go through the shared collapse helpers. **Never** hand-roll it with the `hidden` attribute, `element.style.display`, `element.hidden = true`, or ad-hoc `classList.add('hidden')` — those skip the shared show/hide animation and the `hidden!`/`hidden` class contract.

- **Markup-only toggle** (a trigger reveals/collapses a panel, no other logic): add `data-controller="ui--collapse"`, mark the collapsible element `data-ui--collapse-target="content"`, and render the trigger with `UI::Collapse::Component` (`chevron: true` for the rotating chevron) — never a hand-wired button (`app/javascript/controllers/ui/collapse_controller.js`).
- **Inside your own Stimulus controller** (you have extra logic — a redirect branch, a query-param check): import `collapse_utils` and call it directly:

  ```js
  import { collapse } from 'utils/collapse_utils'
  // ...
  collapse('show', this.formTarget)   // 'show' | 'hide' | 'toggle'; optional duration (default 200)
  ```

The collapsible element starts hidden with the **`hidden` class** (not the `hidden` attribute) — `collapse` toggles `hidden`/`hidden!` and runs the height/scale transition for you. Use **`hidden!`** when the element also carries a display utility that sorts after `hidden` — any `inline-*`, which every `UI::Button` has. A plain `hidden` renders that panel open, and no component spec can see it: the class is in the attribute, it just loses the cascade. Component specs assert the initial state by class (`have_css("[…].hidden")`), not Capybara visibility — the rack_test driver doesn't evaluate CSS.

## No dead hooks in markup

Only add an `id` or non-utility `class` when something concrete consumes it — a CSS rule, a JS/Stimulus selector, a test fixture, an accessibility attribute. Don't keep or invent "structural identifier" hooks "in case something needs them later."

When deleting an `id`/`class`, grep the repo for the name first:

- Zero consumers: delete it, don't rename it.
- Consumers exist: either update them, or leave the hook in place — the consumers are the *reason* it earns its spot in the markup.

## Helpers are deprecated — render a view component instead

**Never add a helper method, and don't extend an existing one.** Anything a helper would render belongs in a view component that takes what it needs as explicit keyword arguments. `app/helpers/application_helper.rb` is legacy: leave what's there, but move a helper into a component when you touch the line that calls it.

- A *view helper* that only gathers a component's arguments out of controller assigns is still a helper — pass those arguments from the view.
- `ApplicationComponentHelper` is the exception (`number_display`, `check_mark`, `cross_mark`, `strava_link`) — value formatters `ApplicationComponent` already includes, so components call them bare.

**What's banned is the component reaching out, not the number of arguments.** State the controller already owns can be named and passed as one value object — `ComponentStructs::SortState` (built in `ApplicationController#sort_state`) is the pattern; value objects live in `app/services/component_structs/`.

Bundle only what's cohesive — one subject, assembled in one place. `SortState` is "how this table is sorted and what its links carry". A grab-bag of unrelated request facts (`display_dev_info?`, `current_user`) is not a value object, it's `helpers` renamed — those stay individual arguments. `Data.define` for one that only carries its arguments; a plain class when it memoizes derivations, since `Data` instances are frozen and `@x ||=` raises on one.

## ViewComponent rules

This project uses the ViewComponent gem to render components, with Lookbook at `/lookbook`.

- **Prefer an existing component to a new one, extended if needed.** Before creating one, look for a component that already renders the pattern or its core — in `ui/` and the app's own namespaces. A new component whose template is mostly one existing `UI::*` component plus chrome is that component with an argument: ask to extend it (the no-new-argument rule above) rather than wrapping it to avoid asking.
- **Before creating a component, check it earns its class.** If its `component.rb` would hold nothing but `initialize` assigning arguments to ivars, and fewer than 3 callers render it, write a partial instead, with `<%# locals: (…) %>` at the top — `admin/competition_users/_table.html.erb` is the pattern. A component earns its class with logic to name, a cache key to build, or a third caller; past that bar, prefer components to partials.
- **If a view file only renders a single component, consider rendering it from the controller instead** (`render Foo::Component.new(...)`) and deleting the view file — the layout still wraps it.
- Generate a new view component with `rails generate component ComponentName argument1 argument2`.
- View components must initialize with **keyword arguments**. Everything the component needs must be passed in explicitly by the caller — never reach into controller state from inside a component (e.g. `controller.instance_variable_get(:@user)`). If the component needs `@user`, the caller renders `Component.new(user: @user)`.
- In view components, use instance variables directly — don't add `attr_reader`/`attr_accessor`. Reference `@foo` everywhere, including in the template.
- In ViewComponent templates, use the `helpers.` prefix for view helpers (e.g. `helpers.time_ago_in_words`) — a legacy bridge, and a sign the helper wants to be a component.
  - Rule of thumb: try the bare call first. Only add `helpers.` if it fails with `NoMethodError` — route helpers (`competition_path`) and ActionView tag/url builders (`tag.span`, `content_tag`, `link_to`) are mixed into `ViewComponent::Base` directly, so they don't need it.
- **Never nest a component inside a folder that already holds a `component.rb`.** Each component lives in `app/components/<path>/component.rb` (and `spec/components/<path>/component_spec.rb`); siblings go in sibling folders, not subfolders — `leaderboard/punchcard_user_row/`, not `leaderboard/punchcard/user_row/`.
- **Change a component's signature, then open its `component_preview.rb`** — nothing renders every preview in the suite, so a stale one raises `ArgumentError: unknown keyword` on its Lookbook page with the whole suite green. `curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/rails/view_components/<path>/component/<scenario>"` is the check.
- **Cached markup has no digest to maintain** — ViewComponent 4 digests a component's `cache` blocks over what they render, so a fragment moves when anything in it changes.
- **A component that builds its own `cache_key` includes `self.class.cache_digest`.**
- **A component not rendered as a literal constant after `render` needs a `# Template Dependency: Full::Class::Component` line** in the component that uses it — `render(inner_component)`, a collection, or a constant read all count. `UI::Accordion` is the pattern.
- **A `UI::Table::Base` cell block is `instance_exec`'d against the component.** Inside `table.column ... do`, bare calls and `@ivar`s resolve on `UI::Table::Base::Component`, not the view. A bare call raises, but **an `@ivar` fails silently** — it reads `nil`, or worse, an identically-named ivar the table happens to hold. Reach state through the readers the table exposes (`sort_state.search_params`, not `sortable_search_params`), and for anything else assign a local above the block. Above the `UI::Table::Base::Component.new` block the view's own helpers work.
- **Cache rows, never cells.** A `cache(...)` inside a cell digests `UI::Table::Base`'s template rather than the calling partial's, so it would share a fragment with every other table caching that record. Pass `cache_key:` to `UI::Table::Base::Component` instead. A row key has three inputs: the record (automatic), every flag fixed for the render (in `cache_key:`), and every *other* record the row renders (`cache_records:`, which mirrors the controller's `includes` — a cell reading an association the controller doesn't preload is an N+1 and a stale row at once).
- **Moving a view into a component turns its locals into methods.** A `<% x = … %>` computed once per template becomes a method run once per *call site* — which is how a single pluck becomes one per table row. Memoize anything that queries as you move it.
- **Converting a partial to a component is a faithful move, not a cleanup.** Carry the markup over verbatim, including comments and commented-out code: those are often a deliberate stash. The only changes a conversion introduces are the ones the move requires — adding `helpers.` where a helper now needs it. Dead code worth removing goes in its own commit.

## Turbo Drive is on

Links and form submissions go through Turbo. Two things bite, neither as an error — the page just behaves oddly:

- **A controller-rendered component takes its content type from the request.** A Turbo form submission sends `Accept: text/vnd.turbo-stream.html` first, and `render Foo::Component.new(...)` has no template format to override it, so the response comes back as a *stream message* — which Turbo appends to the current page instead of replacing it. Fix it at the controller with `before_action { request.format = :html }` for actions that only ever render pages. (An `.html.erb` view doesn't have this problem: the template's own format sets the content type.)
- **Turbo restores its own snapshot on back/forward**, which `Cache-Control: no-store` can't reach. If what a page renders depends on server state, opt out with `helpers.content_for(:head) { tag.meta(name: "turbo-cache-control", content: "no-cache") }`, and a restoration re-fetches instead of showing a page the user has moved past.

## Manual browser verification

**Every `mcp__playwright__browser_take_screenshot` call must pass a `filename:` that starts with `tmp/`** (e.g. `tmp/tooltip-ride-day.png`). The MCP tool's default root is the project root — a bare filename like `tooltip.png` lands in the working tree, shows up in `git status`, and has to be cleaned up by hand. `tmp/` is gitignored, so screenshots there stay out of commits. This applies to ad-hoc visual verification; PR screenshots are the `frontend-screenshots` skill's.
