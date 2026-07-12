#!/usr/bin/env bash
set -euo pipefail

url="${1:-http://localhost/info}"
requests="${2:-200}"

for i in $(seq 1 "$requests"); do
  curl -s "$url" > /dev/null
done
