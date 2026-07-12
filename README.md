# ASP.NET Core Load Balancing Lab

This repository is a hands-on lab for learning how load balancing works with ASP.NET Core, Docker, and nginx.

The goal is simple:

- run the same API in two separate containers
- place nginx in front of them
- observe how requests are distributed across the instances
- use the container hostname to see which instance answered the request

## What the API does

The application exposes a single endpoint:

- `GET /info`

It returns:

- the container hostname, read from the `HOSTNAME` environment variable
- the current UTC timestamp

That makes it easy to see when nginx sends a request to a different container.

## Architecture

- `app1` and `app2` are two identical ASP.NET Core containers
- both listen internally on port `8080`
- nginx listens on port `80`
- nginx forwards incoming requests to the internal app containers

## Files in this lab

- `Program.cs` - ASP.NET Core minimal API with the `/info` endpoint
- `Dockerfile` - multi-stage build for the application image
- `docker-compose.yml` - local stack with `app1`, `app2`, and `nginx`
- `nginx/default.conf` - nginx reverse proxy and upstream definition

## Prerequisites

- Docker
- Docker Compose

Depending on your installation, you may have either:

- `docker compose`
- `docker-compose`

Use the one available in your environment.

## Run the lab

From the repository root:

```bash
docker-compose up --build
```

If your system uses the newer Docker Compose plugin, the equivalent command is:

```bash
docker compose up --build
```

## Test the balancing

Open this URL in your browser:

```text
http://localhost/info
```

Refresh the page several times. The hostname should alternate between the two app containers.

You can also test with curl:

```bash
curl http://localhost/info
```

## Useful commands

Validate the Compose file:

```bash
docker-compose config
```

Start the stack:

```bash
docker-compose up --build
```

Stop the stack:

```bash
docker-compose down
```

Follow the logs:

```bash
docker-compose logs -f
```

## Reproducible failover experiment

To run the full "stop one backend under load" experiment and save logs in one shot:

```bash
./scripts/run-failover-experiment.sh
```

The script writes artifacts under `results/failover-<timestamp>/`:

- `events.log` - major steps and timing
- `requests.tsv` - per-request status, hostname, and timing
- `nginx.log` - nginx logs during the experiment
- `summary.txt` - quick counts (success/failure and hostname distribution)

Tune behavior with environment variables:

```bash
REQUESTS=200 STOP_AT=60 INTERVAL_SECONDS=0.1 ./scripts/run-failover-experiment.sh
```

## What I learned

- `expose` makes a port available to other containers on the same Docker network, but not to the host machine.
- `ports` publishes a container port to the host.
- nginx is the public entry point in this lab; the ASP.NET Core containers stay internal.
- The `HOSTNAME` value changes because each container is a separate runtime instance.

## Next steps

- add health checks
- study nginx failover behavior
- simulate failures under load
- add a database replication experiment
