#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: send_sms.sh <number> <message>" >&2
  exit 1
fi

number="$1"
shift
message="$*"
termux-sms-send -n "$number" "$message"
