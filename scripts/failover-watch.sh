#!/usr/bin/env bash
set -euo pipefail

url="${1:-http://localhost/info}"

while true; do
  curl -s "$url"
  echo
  sleep 1
done
