#!/bin/sh
set -eu

sh backup.sh

if [ -n "$HONEYBADGER_CHECKIN_URL" ]; then
  wget -qO- "$HONEYBADGER_CHECKIN_URL" > /dev/null 2>&1
fi
