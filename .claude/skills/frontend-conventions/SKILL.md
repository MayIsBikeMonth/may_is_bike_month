---
name: frontend-conventions
description: >-
  May is Bike Month frontend conventions — the `twlink` class for basic
  links, the `number_display` helper for numbers, `UI::Time::Component`
  for time, and ViewComponent rules (keyword arguments, instance variables,
  `helpers.` prefix in templates). Trigger when adding or modifying views
  (`.html.erb`), view components, Stimulus controllers, Tailwind classes,
  or any frontend code that touches styling or interactivity. Stimulus.js
  is the JavaScript framework; SCSS and CoffeeScript files exist but are
  deprecated.
---

# Frontend conventions

This project uses **Stimulus.js** for JavaScript interactivity and **Tailwind CSS** for styling. There are SCSS styles and CoffeeScript files, but they are deprecated — don't add to them.

The `bin/dev` command handles building and updating Tailwind and JS.

## Tailwind classes and helpers

- Basic links should use the `twlink` class.
- **Every number** should be rendered with `number_display(number)`. This applies even when a number is composed into a string with non-numeric values — wrap the number itself, not the surrounding string.
  - "Number" includes years, counts, prices, distances, IDs — anything numeric, even when it reads like a label.
- **Time/dates** should be rendered with `UI::Time::Component`. Don't roll your own `time_ago_in_words` or `strftime` formatting in views.

## ViewComponent rules

This project uses the ViewComponent gem to render components.

- **Prefer view components to partials.**
- Generate a new view component with `rails generate component ComponentName argument1 argument2`.
- View components must initialize with **keyword arguments**. Everything the component needs must be passed in explicitly by the caller — never reach into controller state from inside a component. If the component needs `@user`, the caller renders `Component.new(user: @user)`.
- In view components, **prefer instance variables to `attr_accessor`**.
- In ViewComponent templates, use the `helpers.` prefix for view helpers (e.g. `helpers.time_ago_in_words`).
  - You don't need to prefix paths (e.g. do `new_bike_path`, NOT `helpers.new_bike_path`).
