---
name: use-existing-markup
description: >-
  Convert a branch's hand-written markup to the `UI::*` components that already
  render it, revert mockup-driven variants the branch added to shared components,
  snap buttons and badges to existing colors, and report shadows and hover states.
  Trigger when a branch adds or redesigns a page's markup, or on "use existing
  components", "reuse the markup", "is this hand-rolled", and from the `pr`
  skill's markup audit. It replaces without asking.
---

# Use existing markup

## Find what the branch adds

```bash
rtk proxy git diff origin/main...HEAD -U0 -- '*.erb' 'app/components/*.rb' |
  grep -E '^(\+\+\+ |\+.*(<[a-z]|link_to|button_to|content_tag|tag\.|image_tag))'
rtk proxy git diff origin/main...HEAD --name-only --diff-filter=A -- app/assets/images app/components
```

Treat the output as a map of where to read. Read the templates whole.

## Undo what the branch added to a shared component

```bash
rtk proxy git diff origin/main...HEAD -- app/components/ui
```

**Every keyword argument, variant or color the branch added there to match a mockup is an override.** Revert that component and its spec to `origin/main` and render the default at the call site, without asking. A variant added for one caller stays for every caller. The exception is an argument the user asked for in this conversation.

**The same override can sit outside the component** — a wrapper whose classes restyle what renders inside it (`<span class="uppercase tracking-wider">` around a `UI::Badge`). Strip those classes and keep only the wrapper's layout (margin, display, grid placement); drop the wrapper if layout was all it carried.

## Replace, don't ask

Read `app/components/ui/` and convert every hand-written piece an existing component covers, then name each visible change in your reply:

- cards → `UI::Card`
- headings → `UI::Header`
- pills → `UI::Badge`
- buttons → `UI::Button`; links styled as buttons, or a `link_to … method:` → `UI::ButtonLink`
- tables → `UI::Table`, definition lists → `UI::DefinitionList`
- alerts, modals, tooltips, dropdowns, times → `UI::Alert`, `UI::Modal`, `UI::Tooltip`, `UI::Dropdown`, `UI::Time` (`frontend-conventions` covers time)

**Snap to the nearest existing variant rather than overriding one.** A hand-colored button becomes the closest `UI::Button` `color:` and `size:`, with the override classes deleted — don't write `html_class: "bg-[#…]! px-8!"`. A badge gets the nearest `UI::Badge` `color:`. `!` is for layout only (width, padding, grid placement).

## Icons and images

Check every icon or image the branch adds against `app/assets/images/` — the same drawing under another name (`grep -rlF -- "<svg path d=…>" app`) or the same subject (`ls app/assets/images | grep -i <subject>`). Use the existing file and delete the added one.

## Shadows

- **Remove small shadows** (`shadow-sm`, `shadow`, a `shadow-[…]` with a few pixels of blur) — on a static card they read as a hover state.
- **Keep big shadows** (`shadow-md` and up, `drop-shadow-[…]` on an image), but call each one out; the user decides.

## Hover states

**Call out every hover state on something that isn't a `UI::Button` or `UI::ButtonLink`** — a `hover:` utility on a card, row or label, a `group-hover:`. Say what it's on and what it does. Don't remove it. A `twlink`'s own hover is the standard link style; leave it out.

## The reply

Lead with the conversions. The user should never find a change to their page that the reply didn't mention.

1. Each conversion, and each component argument reverted, with the visible change it makes.
2. Each big shadow kept.
3. Each hover state on a non-button.
4. Each hand-written piece kept, and what no component covers.
