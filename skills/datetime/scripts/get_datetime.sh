#!/usr/bin/env bash
#
# get_datetime.sh — print the current date and time in several useful formats.
#
# Used by the `datetime` Claude skill so Claude can answer questions that
# depend on the real current date/time instead of guessing from its training
# data.
#
# Usage:
#   bash skills/datetime/scripts/get_datetime.sh              # local timezone
#   bash skills/datetime/scripts/get_datetime.sh UTC          # override TZ
#   bash skills/datetime/scripts/get_datetime.sh Asia/Kolkata # IANA zone
#
# Output is a small key=value block, one field per line, easy for Claude to
# read and for humans to eyeball.

set -euo pipefail

if [[ $# -gt 0 && -n "$1" ]]; then
  export TZ="$1"
fi

local_iso=$(date "+%Y-%m-%dT%H:%M:%S%z")
local_human=$(date "+%Y-%m-%d %H:%M:%S %Z")
utc_iso=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
utc_human=$(date -u "+%Y-%m-%d %H:%M:%S UTC")
weekday=$(date "+%A")
unix_ts=$(date "+%s")
tz_name=$(date "+%Z")
tz_offset=$(date "+%z")

cat <<EOF
local_iso=${local_iso}
local_human=${local_human}
utc_iso=${utc_iso}
utc_human=${utc_human}
weekday=${weekday}
unix_timestamp=${unix_ts}
timezone_name=${tz_name}
timezone_offset=${tz_offset}
EOF
