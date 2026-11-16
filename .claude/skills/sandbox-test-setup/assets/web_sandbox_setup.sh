#!/bin/bash
# One-shot setup for the Claude Code web sandbox (/home/user/may_is_bike_month).
#
#   bash .claude/skills/sandbox-test-setup/assets/web_sandbox_setup.sh [--dev-server]
#
# Ruby (built from source on a cold container), postgres, redis, the local jsdelivr
# stand-in, then `bin/workspace_setup --without_seeds`, the pinned Playwright Chromium,
# the Tailwind build and a background seed of an empty development database
# (/tmp/seed.status). Idempotent; --dev-server also boots bin/dev.
#
# Logs: /tmp/ruby_build.log, /tmp/system_setup.log, /tmp/cdn_server.log, /tmp/playwright_install.log,
#       /tmp/seed.log (+ /tmp/seed.status), /tmp/dev_server.log
set -uo pipefail

REPO="${CLAUDE_PROJECT_DIR:-/home/user/may_is_bike_month}"
RUBYVER=$(awk '$1=="ruby"{print $2}' "$REPO/.tool-versions")
RUBY_PREFIX="/opt/ruby-${RUBYVER}/x64"

# PG*: database.yml reads them outside CI. LOCAL_CHROME_OVERRIDE: spec/support/local_chrome.rb
# adds the root-in-a-container flags and routes jsdelivr to the stand-in below.
ENV_EXPORTS="export PATH=\"$RUBY_PREFIX/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin\"
export LD_LIBRARY_PATH=\"$RUBY_PREFIX/lib:\${LD_LIBRARY_PATH:-}\"
export PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
export PGHOST=127.0.0.1 PGUSER=rails PGPASSWORD=password
export LOCAL_CHROME_OVERRIDE=1
export LANG=C.UTF-8 LC_ALL=C.UTF-8"
eval "$ENV_EXPORTS"

say() { echo "==> $*"; }

ruby_is_built() { "$RUBY_PREFIX/bin/ruby" --version 2>/dev/null | grep -q "^ruby ${RUBYVER}"; }

# ---------------------------------------------------------------- ruby build
build_ruby() {
  set -e
  local src="/tmp/ruby-build-src/ruby-${RUBYVER}"
  mkdir -p /tmp/ruby-build-src
  # The release tarball ships ./configure and the bundled gems; the tag is the fallback
  [ -d "$src" ] || curl -sfL --max-time 300 "https://cache.ruby-lang.org/pub/ruby/${RUBYVER%.*}/ruby-${RUBYVER}.tar.gz" \
    | tar -C /tmp/ruby-build-src -xz ||
    { rm -rf "$src"; git clone --depth 1 --branch "v${RUBYVER}" https://github.com/ruby/ruby.git "$src"; }
  cd "$src"
  [ -f configure ] || ./autogen.sh
  # A git checkout lacks the bundled gems, and `make install` would fetch them through
  # rubygems' own cert store, which the egress proxy breaks
  awk '$1 !~ /^#/ && NF {print $1, $2}' gems/bundled_gems \
    | xargs -P8 -n2 bash -c '[ -s "gems/$0-$1.gem" ] || curl -sfL --max-time 60 \
        -o "gems/$0-$1.gem" "https://rubygems.org/downloads/$0-$1.gem"'
  mkdir -p /tmp/ruby-build-src/build && cd /tmp/ruby-build-src/build
  [ -f Makefile ] || "$src/configure" --prefix="$RUBY_PREFIX" \
    --enable-shared --disable-install-doc --with-openssl-dir=/usr
  make -j"$(nproc)"
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt make install
  "$RUBY_PREFIX/bin/ruby" --version
}

# ------------------------------------------------- jsdelivr stand-in for :js specs
# local_chrome.rb maps cdn.jsdelivr.net to 127.0.0.1:8443 (Chrome rejects the egress
# proxy's CA), so this always runs. Each jsdelivr pin in config/importmap.rb is mirrored
# into jsdelivr's URL layout with curl, which trusts the proxy - along with the `/npm/…`
# modules a `+esm` build imports.
mirror_jsdelivr() { # <path under /npm/>
  local out="/tmp/cdn/serve/npm/$1" import
  [ -s "$out" ] && return 0
  mkdir -p "$(dirname "$out")"
  curl -sfL --max-time 60 -o "$out" "https://cdn.jsdelivr.net/npm/$1" || { rm -f "$out"; return 1; }
  for import in $(grep -oE '"/npm/[^"]+"' "$out" | tr -d '"' | sort -u); do
    mirror_jsdelivr "${import#/npm/}"
  done
}

# Where jsdelivr itself is refused: the package from registry.npmjs.org. Only a pin to a
# file in the package works this way - a `+esm` build has no equivalent there.
mirror_npm() { # <name> <version>
  local dir="/tmp/cdn/serve/npm/$1@$2"
  [ -s "$dir/package.json" ] && return 0
  mkdir -p "$dir"
  curl -sfL --max-time 60 "https://registry.npmjs.org/$1/-/${1#*/}-$2.tgz" | tar -xz -C "$dir" --strip-components=1
}

setup_cdn() {
  local url spec
  mkdir -p /tmp/cdn/serve/npm
  for url in $(grep -oE 'https://cdn\.jsdelivr\.net/npm/[^"]+' "$REPO/config/importmap.rb"); do
    spec=${url#https://cdn.jsdelivr.net/npm/}
    mirror_jsdelivr "$spec" && continue
    [[ $spec =~ ^((@[^/]+/)?[^@/]+)@([^/]+)/(.*)$ ]] && [ "${BASH_REMATCH[4]}" != "+esm" ] &&
      mirror_npm "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}" && continue
    echo "couldn't mirror $url - pages importing it will break in :js specs"
  done

  [ -s /tmp/cdn/cert.pem ] || openssl req -x509 -newkey rsa:2048 -keyout /tmp/cdn/key.pem \
    -out /tmp/cdn/cert.pem -sha256 -days 365 -nodes -subj "/CN=cdn.jsdelivr.net" \
    -addext "subjectAltName=DNS:cdn.jsdelivr.net" 2>/dev/null
  curl -sk -o /dev/null https://127.0.0.1:8443/ ||
    setsid nohup python3 "$REPO/.claude/skills/sandbox-test-setup/assets/cdn_server.py" \
      </dev/null >/tmp/cdn_server.log 2>&1 &
}

# ------------------------------------- everything that needs no Ruby, in parallel
setup_system() {
  # ruby-vips, for image_processing's Active Storage variants
  if ! ldconfig -p | grep -q libvips.so.42; then
    apt-get install -y --no-install-recommends libvips42 ||
      { apt-get update && apt-get install -y --no-install-recommends libvips42; }
  fi

  service postgresql start >/dev/null
  service redis-server start 2>&1 | grep -v ulimit
  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='rails'" | grep -q 1 ||
    sudo -u postgres psql -c "CREATE USER rails WITH SUPERUSER PASSWORD 'password';"

  # Playwright MCP's `chrome` channel: a wrapper,
  # since we're root and a plain symlink dies without --no-sandbox
  local chrome_dir
  chrome_dir="$(ls -d /opt/pw-browsers/chromium-*/chrome-linux* 2>/dev/null | sort -V | tail -1)"
  if [ -x "$chrome_dir/chrome" ]; then
    mkdir -p /opt/google/chrome /root/.cache/ms-playwright
    printf '#!/bin/bash\nexec "%s" --no-sandbox --disable-dev-shm-usage "$@"\n' "$chrome_dir/chrome" \
      > /opt/google/chrome/chrome
    chmod +x /opt/google/chrome/chrome
    [ -s /root/.cache/ms-playwright/mcp-auth.json ] ||
      printf '{"cookies":[],"origins":[]}' > /root/.cache/ms-playwright/mcp-auth.json
  else
    echo "no chromium under /opt/pw-browsers - MCP screenshots will not work"
  fi

  setup_cdn
}

DEV_SERVER=0
[ "${1:-}" != "--dev-server" ] || DEV_SERVER=1

say "starting system setup and (if needed) the ruby build together"
setup_system > /tmp/system_setup.log 2>&1 &
SYSTEM_PID=$!

if ruby_is_built; then
  say "ruby ${RUBYVER} already installed"
else
  say "building ruby ${RUBYVER} from source (~6-10 min on 4 cores) -> /tmp/ruby_build.log"
  build_ruby > /tmp/ruby_build.log 2>&1 || { echo "ruby build FAILED - see /tmp/ruby_build.log"; tail -20 /tmp/ruby_build.log; exit 1; }
fi

wait "$SYSTEM_PID" || say "system setup had a problem - see /tmp/system_setup.log"

cd "$REPO"

say "bin/workspace_setup --without_seeds"
bin/workspace_setup --without_seeds || exit 1

# The pin can want a newer build than /opt/pw-browsers ships; the :js specs launch this one
say "installing the pinned Playwright Chromium -> /tmp/playwright_install.log"
npx --no-install playwright install chromium-headless-shell >/tmp/playwright_install.log 2>&1 ||
  say "playwright install failed - :js specs will not run"

# After workspace_setup: .workspace_id gives BASE_URL its port
eval "$(ruby bin/env --export)"

# bin/setup doesn't build the CSS, and every layout-rendering spec needs it
say "building tailwind"
bin/rails tailwindcss:build >/dev/null 2>&1 || say "tailwindcss:build failed - run it by hand"

# Detached with every fd redirected, else the SessionStart hook waits on it. psql
# because a Rails boot is several seconds.
SEED_STATUS=/tmp/seed.status
DEV_DB="may_is_bike_month_development_${WORKSPACE_ID}"
SEEDED=$(psql -d "$DEV_DB" -tAc 'SELECT EXISTS (SELECT 1 FROM users)' 2>&1)
if [ "$SEEDED" = "f" ]; then
  say "seeding the development database in the background -> /tmp/seed.log"
  say "  wait for it: until grep -qx 'done\|failed' $SEED_STATUS; do sleep 5; done"
  echo running > "$SEED_STATUS"
  setsid nohup bash -c "bundle exec rails db:seed && s=done || s=failed; echo \$s > $SEED_STATUS" \
    </dev/null >/tmp/seed.log 2>&1 &
elif [ "$SEEDED" = "t" ]; then
  echo done > "$SEED_STATUS"
  say "development database already seeded"
else
  echo failed > "$SEED_STATUS"
  say "couldn't tell whether $DEV_DB is seeded, so didn't seed it: $SEEDED"
fi

if [ "$DEV_SERVER" = 1 ]; then
  say "starting bin/dev -> /tmp/dev_server.log"
  setsid nohup bin/dev </dev/null >/tmp/dev_server.log 2>&1 &
  # Bounded, so a server that dies on boot doesn't hang the hook
  for _ in $(seq 1 48); do curl -fs -o /dev/null "$BASE_URL/" && break; sleep 5; done
  if curl -fs -o /dev/null "$BASE_URL/"; then
    say "dev server up at $BASE_URL"
  else
    say "dev server never answered on $BASE_URL - see /tmp/dev_server.log"
    tail -20 /tmp/dev_server.log
  fi
fi

# Set by the SessionStart hook; what's written here is exported into the session's shells
if [ -n "${CLAUDE_ENV_FILE:-}" ] && ! grep -qF "$RUBY_PREFIX/bin" "$CLAUDE_ENV_FILE" 2>/dev/null; then
  printf '%s\n' "$ENV_EXPORTS" >> "$CLAUDE_ENV_FILE"
  say "wrote the toolchain env to \$CLAUDE_ENV_FILE"
fi

say "done. Shell env for later commands:"
printf '%s\n' "$ENV_EXPORTS" 'eval "$(ruby bin/env --export)"' | sed 's/^/  /'
