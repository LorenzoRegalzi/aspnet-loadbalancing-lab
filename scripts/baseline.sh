#!/usr/bin/env bash
set -euo pipefail

url="${1:-http://localhost/info}"
requests="${2:-20}"
delay_seconds="${3:-1}"

for i in $(seq 1 "$requests"); do
  curl -s "$url"
  echo
  sleep "$delay_seconds"
done
