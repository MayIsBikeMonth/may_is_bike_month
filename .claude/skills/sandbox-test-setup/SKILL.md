---
name: sandbox-test-setup
description: >-
  May is Bike Month Ruby + RSpec environment setup for each place this repo runs: a
  local macOS Conductor workspace, a spawned `.claude/worktrees/…` git worktree, and
  Claude Code's Linux web sandbox (`/home/user/may_is_bike_month`) — getting `ruby`,
  `bundle`, `bin/lint`, a database, seeds, a dev server and a browser working there.
  **Read it before the first command in a spawned worktree**, which starts with
  `bin/workspace_setup` (without it `bin/env` hands back the main checkout's port,
  database and Redis). Read it whenever a session runs RSpec, `bundle` or `bin/lint`,
  needs a dev server or seeded data, or hits: a missing `.workspace_id`, `Could not find
  'bundler' (4.0.x)`, `Bundler::RubyVersionMismatch`, `command not found: rspec`, a
  syntax error from bare `ruby` on `{x:}` shorthand, unstyled pages or visibility
  assertions failing in `:js` specs (missing `tailwind.css`), a chromedriver version
  mismatch, `PG::ConnectionBad`, or `Running as root without --no-sandbox is not
  supported`. The fix is almost never a reinstall or a Gemfile edit — it's a PATH, an
  env var, or a service that isn't running.
---

# Running Ruby + RSpec for May is Bike Month

Read the reference for the path you're in; the others don't apply.

| Path | Environment | Read |
| --- | --- | --- |
| `/Users/…/conductor/workspaces/…` | local macOS Conductor workspace | `references/local-macos.md` |
| `…/.claude/worktrees/…` | spawned git worktree — set it up first, below | `references/local-macos.md` |
| `/home/user/may_is_bike_month` (`$CLAUDE_CODE_REMOTE=true`) | Claude Code web sandbox | `references/web-sandbox.md` |

## A spawned worktree sets itself up first

Before the first `rspec`, `bundle`, `bin/lint`, `bin/env` or dev server:

```bash
bin/workspace_setup --without_seeds
```

The `SessionStart` hook `.claude/hooks/worktree-setup.sh` runs this on a worktree's
first session, so a `.workspace_id` is usually already there. When it isn't, the
hook's output went to `tmp/workspace_setup.log`; read that, then run the command by hand.
When Claude Code removes the worktree, `.claude/hooks/worktree-teardown.sh` runs
`bin/workspace_teardown` to drop its databases, then `git worktree remove`. One with
uncommitted changes stays, databases and all.

It allocates an ID from the `dev_workspaces` registry, writes `.workspace_id`, and runs
`bin/setup`, which installs gems and npm packages and creates this workspace's
databases. Run `bundle exec rails db:seed` when you need records. `node_modules` starts
as a clone of the root checkout's, so `npm install` only fetches what this branch
changed.

**Never write `.workspace_id` yourself** — `bin/workspace_setup` then skips allocation,
leaving an ID the registry never handed out. And skipping setup entirely silently falls
back to `DEV_PORT=3010`: the main checkout's port, database and Redis — and a
`bin/setup` from there loads the schema over the main checkout's database.

## Build the CSS (every environment)

`bin/setup` doesn't build Tailwind. In a checkout where `bin/dev` hasn't run,
`app/assets/builds/` is empty, and since the layout's `stylesheet_link_tag :app` just
globs what's there, nothing errors — pages render unstyled, `hidden` doesn't hide, and
`:js` specs fail visibility assertions in ways that read as flakes. It isn't
pre-existing; build it:

```bash
bundle exec rails tailwindcss:build
```

## Who starts `bin/dev`

Where a human works — a Conductor workspace, the main checkout — ask. In a spawned
worktree or the web sandbox, the checkout is yours: start it yourself.
