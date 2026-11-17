# Claude Code web sandbox

**The `SessionStart` hook (`.claude/hooks/session-start.sh`) has already set this up**:
Ruby, gems, `node_modules`, postgres, redis, the Tailwind build, the pinned Playwright
Chromium, the local jsdelivr stand-in, and `$PATH`/`PG*`/`PLAYWRIGHT_BROWSERS_PATH`/
`LOCAL_CHROME_OVERRIDE` exported into your shells. Check with `ruby -v` and `pg_isready` before setting anything
up.

The hook runs `assets/web_sandbox_setup.sh`. Re-run it when the hook didn't finish or an
idle container dropped postgres/redis (a `PG::ConnectionBad`) — it's idempotent:

```bash
bash .claude/skills/sandbox-test-setup/assets/web_sandbox_setup.sh              # setup
bash .claude/skills/sandbox-test-setup/assets/web_sandbox_setup.sh --dev-server # + bin/dev
```

Then:

```bash
bundle exec rspec spec/models spec/requests
bundle exec rspec spec/integration spec/components   # :js specs need LOCAL_CHROME_OVERRIDE=1, which the hook exports
```

## The seed runs in the background

The script seeds an empty development database after setup, detached so the session
doesn't wait on it. Wait on it before anything that reads development data — a
screenshot, `rails runner`, `$BASE_URL`:

```bash
until grep -qx 'done\|failed' /tmp/seed.status; do sleep 5; done; cat /tmp/seed.status
```

Log in `/tmp/seed.log`. An unseeded database doesn't say so — the leaderboard just
renders empty.

## How the script gets Ruby

There's no prebuilt Ruby for this repo, so a cold container builds it from source —
`build_ruby()` in the script, from the cache.ruby-lang.org tarball or a git clone of the
tag, ~6–10 min on 4 cores; log in `/tmp/ruby_build.log`. Its log looks like it restarts
(miniruby, the real build, each ext's `configure`); it isn't. `make install` would fetch
the bundled gems through rubygems' own cert store, which the egress proxy breaks, so the
script pre-stages them with `curl` first.

**The pin is `.tool-versions`' `ruby` line.** Never fall back to 3.x and patch the
Gemfile — Bundler 4's resolver differs and you'll chase fake regressions.

## By hand

The script prints its env block at the end; it's also this:

```bash
export PATH="/opt/ruby-4.0.9/x64/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin"  # service is in /usr/sbin
export LD_LIBRARY_PATH="/opt/ruby-4.0.9/x64/lib:$LD_LIBRARY_PATH"
export PGHOST=127.0.0.1 PGUSER=rails PGPASSWORD=password  # database.yml reads these outside CI
export LOCAL_CHROME_OVERRIDE=1
export LANG=C.UTF-8 LC_ALL=C.UTF-8  # else foreman dies reading .env: invalid byte sequence in US-ASCII

service postgresql start; service redis-server start
sudo -u postgres psql -c "CREATE USER rails WITH SUPERUSER PASSWORD 'password';"  # once
bin/workspace_setup --without_seeds   # .workspace_id, bundle, npm, databases
bundle exec rails tailwindcss:build
eval "$(ruby bin/env --export)"
```

Don't set `CI=1` — `database.yml` then wants a `postgres` user with password `password`
on 127.0.0.1, the GitHub Actions service container's, not the `rails` user created here.

## The dev server

Start it yourself — the container is yours (SKILL.md). It never returns, so background
it and poll:

```bash
nohup bin/dev > /tmp/dev_server.log 2>&1 &
until curl -fs -o /dev/null "$BASE_URL/"; do sleep 5; done
```

**Poll the artifact, never a duration.** A backgrounded command returns exit 0
immediately, and `sleep 300` has come back in well under 300s here.

## `:js, type: :system` specs

They run through capybara-playwright-driver, which launches the `playwright` npm package's
own Chromium. Two things the script handles, and what to check when one of them breaks:

- **Chromium** has to be the build the `playwright` pin in `package.json` wants, which can
  be newer than the one under `/opt/pw-browsers`, so the script runs
  `npx playwright install chromium-headless-shell` into `$PLAYWRIGHT_BROWSERS_PATH`.
  `Executable doesn't exist at /opt/pw-browsers/...` means that step failed — see
  `/tmp/playwright_install.log`. `spec/support/local_chrome.rb` adds `--no-sandbox`, because
  we're root.
- **jsdelivr**: `config/importmap.rb` pins luxon, `@bikeindex/time-localizer`,
  `@floating-ui/dom` and `@honeybadger-io/js` from `cdn.jsdelivr.net`, and Chrome rejects
  the egress proxy's CA. With `LOCAL_CHROME_OVERRIDE=1`, `spec/support/local_chrome.rb`
  maps `cdn.jsdelivr.net` to `127.0.0.1:8443`, where `assets/cdn_server.py` serves
  `/tmp/cdn/serve` — a mirror of every jsdelivr pin (and the `/npm/…` modules a `+esm`
  build imports) fetched with `curl`. A page that renders empty, or a Stimulus
  controller that never connects, means the mirror is missing a file or the server is
  down: `curl -sk https://127.0.0.1:8443/npm/luxon@3.7.1/build/es6/luxon.js | head -c 80`,
  and `/tmp/cdn_server.log`. A changed pin is picked up by re-running the script.

## Playwright MCP

The `/opt/pw-browsers` Chromium, through `/opt/google/chrome/chrome` — a **wrapper
script** adding `--no-sandbox`, since a plain symlink dies with `Running as root without
--no-sandbox is not supported`, which reads like a missing browser. `/root/.cache/ms-playwright/mcp-auth.json` has
to exist (`{"cookies":[],"origins":[]}`); the script writes it. It has no
host-resolver mapping, so it **can't load the jsdelivr pins** — `@bikeindex/time-localizer`
is imported at the top of `application.js`, so no Stimulus controller connects in it.
Screenshots of static layout still work; interaction doesn't.

## Network

Set by the environment's network policy, so it moves — probe rather than trust this:
`curl -sIL --max-time 5 -o /dev/null -w "%{http_code}\n" https://<host>`.

Usually **reachable** with `curl`: github.com, rubygems.org, registry.npmjs.org,
storage.googleapis.com, cache.ruby-lang.org, cdn.jsdelivr.net. **Refused**:
download.ruby-lang.org, and GitHub's archive tarballs (`codeload.github.com`) — `git
clone` the tag instead. If a tool's default download URL is refused, look for a GitHub
or npm-registry alternative before giving up.
