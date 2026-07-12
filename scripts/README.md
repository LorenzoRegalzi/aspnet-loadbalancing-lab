# Scripts

These scripts are small helpers for the load balancing lab.

## `baseline.sh`

Prints a sequence of responses from `GET /info` so you can verify the round-robin behavior.

Usage:

```bash
./scripts/baseline.sh
```

Optional arguments:

```bash
./scripts/baseline.sh <url> <requests> <delay-seconds>
```

Example:

```bash
./scripts/baseline.sh http://localhost/info 20 1
```

## `load.sh`

Generates a simple burst of requests and discards the output.

Usage:

```bash
./scripts/load.sh
```

Optional arguments:

```bash
./scripts/load.sh <url> <requests>
```

Example:

```bash
./scripts/load.sh http://localhost/info 500
```

## `failover-watch.sh`

Runs an endless one-request-per-second loop so you can observe behavior while stopping a backend container.

Usage:

```bash
./scripts/failover-watch.sh
```

## `run-failover-experiment.sh`

Runs the full failover experiment and writes structured logs under `results/`.

What it does:

- starts the stack (`up -d --build`)
- sends a configurable number of requests to `/info`
- stops `app1` at a configurable request index
- captures request-level data and nginx logs
- writes a short summary

Usage:

```bash
./scripts/run-failover-experiment.sh
```

Useful environment variables:

```bash
URL=http://localhost/info
REQUESTS=120
STOP_AT=40
INTERVAL_SECONDS=0.2
```

Example:

```bash
REQUESTS=200 STOP_AT=60 INTERVAL_SECONDS=0.1 ./scripts/run-failover-experiment.sh
```

Dry-run mode (no Docker calls, useful to test the script flow):

```bash
DRY_RUN=1 ./scripts/run-failover-experiment.sh
```
