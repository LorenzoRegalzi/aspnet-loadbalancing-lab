#!/usr/bin/env bash
set -euo pipefail

URL="${URL:-http://localhost/info}"
REQUESTS="${REQUESTS:-120}"
STOP_AT="${STOP_AT:-40}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-0.2}"
DRY_RUN="${DRY_RUN:-0}"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
out_dir="results/failover-${timestamp}"
mkdir -p "$out_dir"

events_log="$out_dir/events.log"
requests_tsv="$out_dir/requests.tsv"
nginx_log="$out_dir/nginx.log"
summary_file="$out_dir/summary.txt"

compose_cmd=""
if [[ "$DRY_RUN" == "0" ]]; then
  if docker compose version >/dev/null 2>&1; then
    compose_cmd="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    compose_cmd="docker-compose"
  else
    echo "No Docker Compose command found (docker compose or docker-compose)." >&2
    exit 1
  fi
fi

log_event() {
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" | tee -a "$events_log" >/dev/null
}

log_event "Starting failover experiment"
log_event "Settings: URL=$URL REQUESTS=$REQUESTS STOP_AT=$STOP_AT INTERVAL_SECONDS=$INTERVAL_SECONDS DRY_RUN=$DRY_RUN"

nginx_logs_pid=""
cleanup() {
  if [[ -n "$nginx_logs_pid" ]]; then
    kill "$nginx_logs_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [[ "$DRY_RUN" == "0" ]]; then
  log_event "Bringing stack up"
  $compose_cmd up -d --build >/dev/null
  log_event "Starting nginx log capture"
  $compose_cmd logs -f nginx >"$nginx_log" 2>&1 &
  nginx_logs_pid="$!"
else
  log_event "Dry run enabled: Docker commands are skipped"
fi

printf 'index\tlocal_time_utc\thttp_code\thostname\tapi_timestamp\terror\n' > "$requests_tsv"

success_count=0
failure_count=0

for i in $(seq 1 "$REQUESTS"); do
  if [[ "$i" == "$STOP_AT" ]]; then
    if [[ "$DRY_RUN" == "0" ]]; then
      log_event "Stopping app1 at request index $i"
      $compose_cmd stop app1 >>"$events_log" 2>&1
    else
      log_event "Dry run: would stop app1 at request index $i"
    fi
  fi

  local_time="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"
  body_file="$out_dir/.body.tmp"
  err_file="$out_dir/.err.tmp"

  if [[ "$DRY_RUN" == "0" ]]; then
    http_code="$(curl -sS -m 2 -o "$body_file" -w "%{http_code}" "$URL" 2>"$err_file" || true)"
  else
    if (( i < STOP_AT )); then
      echo '{"hostname":"app1-sim","timestamp":"2026-01-01T00:00:00Z"}' > "$body_file"
      : > "$err_file"
      http_code="200"
    elif (( i == STOP_AT )); then
      : > "$body_file"
      echo 'simulated connection failure' > "$err_file"
      http_code="000"
    else
      echo '{"hostname":"app2-sim","timestamp":"2026-01-01T00:00:00Z"}' > "$body_file"
      : > "$err_file"
      http_code="200"
    fi
  fi

  body="$(cat "$body_file")"
  err_msg="$(tr '\n' ' ' < "$err_file" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  hostname="$(printf '%s' "$body" | sed -n 's/.*"hostname":"\([^"]*\)".*/\1/p')"
  api_ts="$(printf '%s' "$body" | sed -n 's/.*"timestamp":"\([^"]*\)".*/\1/p')"

  if [[ "$http_code" == "200" ]]; then
    success_count=$((success_count + 1))
  else
    failure_count=$((failure_count + 1))
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$i" "$local_time" "$http_code" "$hostname" "$api_ts" "$err_msg" >> "$requests_tsv"

  sleep "$INTERVAL_SECONDS"
done

rm -f "$out_dir/.body.tmp" "$out_dir/.err.tmp"

{
  echo "Failover experiment summary"
  echo "Output directory: $out_dir"
  echo "Total requests: $REQUESTS"
  echo "Success (HTTP 200): $success_count"
  echo "Failures (non-200): $failure_count"
  echo
  echo "Responses by hostname:"
  awk -F '\t' 'NR>1 && $4!="" {count[$4]++} END {for (h in count) printf "%s\t%d\n", h, count[h]}' "$requests_tsv" | sort
} > "$summary_file"

log_event "Experiment completed"
log_event "Summary written to $summary_file"

cat "$summary_file"
