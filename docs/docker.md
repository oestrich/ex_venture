# Docker Environment

By using [Docker][docker] and [Docker-Compose][docker-compose], you may quickly launch a running copy of the game without necessarily having all of the Elixir development toolchain installed and configured as described in the Setup documentation.

## Features

The included `docker-compose.yml` supports the following components, some of which are optional:

- ExVenture - game server
- [PostgreSQL][postgresql] - stores game state
- [Prometheus][prometheus] - automatically records metrics about the running game
- [Grafana][grafana] - allows browsing of Prometheus metrics with visual graphs and dashboards
- [postgres_exporter][postgres_exporter] - A Prometheus exporter to track SQL-specific metrics about the included database

## Requirements

### Docker

This environment has been tested with [Docker For Mac][docker-for-mac] `18.06.0-ce` on OSX 10.13.6 and Arch Linux, but should be compatible with most versions 18.02 and above, as long as they support the included Docker-Compose syntax and its version as noted below.

### Docker-Compose

This environment has been tested with Docker-Compose version 1.22.0, but should be compatible with any versions that support the [Compose YAML schema][compose-file] version `3.6`.

## Getting Started

### Pull Images

First, download any standard/non-custom Docker images used in the `docker-compose.yml`:

```bash
docker-compose pull
```

### Build ExVenture Image

Build a custom Docker image containing the ExVenture game server using the included Dockerfile:

```bash
docker-compose build ex_venture
```

The included Dockerfile uses a feature known as Multi-Stage Builds to produce a final image that is much smaller and more self-contained, without including the necessary development tools that are used to compile the project and its static assets.

This may take a few minutes the first time, depending on your internet and CPU speeds. Later builds should be much faster, provided you don't remove the cached images or make substantial changes to the Dockerfile or the Mix dependencies.

### Set Up Database

First, launch the PostgreSQL database in the background, as we aren't usually concerned with its log output:

```bash
docker-compose up -d postgres
```

Now run two of ExVenture's distillery tasks to perform Database Migrations and seed the database with game content:

```bash
docker-compose run --rm ex_venture migrate
docker-compose run --rm ex_venture seed
```

### Start The Game

Launch the game with streaming log output:

```bash
docker-compose up ex_venture
```

Launch the game in the background:

```bash
docker-compose up -d ex_venture
```

Stream logs from a detached container:

```bash
docker-compose logs -f ex_venture
```

### Launch All Optional Components

You can examine the `docker-compose.yml` to see the full contents of this environment, but you can launch them all with:

```bash
docker-compose up -d
```

## Usage

### Examine Running Containers

The following command will list all known containers in the environment, their status, and any forwarded network ports:

```bash
docker-compose ps
```

### Accessing The Game

You may visit the game in a browser at http://localhost:4000 or via Telnet at `localhost`, port 5555.

### Accessing The Metrics

You may visit the included Grafana tool in a browser at http://localhost:3000, which includes the same dashboard used by the author for monitoring the live game at [Midmud][midmud].

You may visit the included Proemtheus tool in a browser at http://localhost:9090, and see what Targets it's configured to scrape from at [http://localhost:9090/targets](http://localhost:9090/targets).

### Accessing The Database

The PostgreSQL database has been port-forwarded on port `15432`, and can be accessed with default credentials of `ex_venture` for both username/password, as defined in the `docker-compose.yml`. This can be disabled by removing the `ports:` segment of the YAML underneath the `postgres` heading, or the credentials may be replaced in the `environment` block. This will require changes to the `config/prod.docker.exs` file to account for the revised credentials.

## Cleaning Up

### Stopping The Environment

You can remove the Docker containers and Docker network that this environment creates with the `down` subcommand:

```bash
docker-compose down
```

Data stored in Docker volumes, such as the PostgreSQL contents or Grafana/Prometheus state, should persist.

### Starting Fresh

This variation of the `down` command will also remove any local data volumes, allowing you to start the game with fresh content as defined by the `seeds` task.

```bash
docker-compose down --volumes
```

This variation of the `down` command will also remove any locally-built Docker images that aren't using the `image:` key in `docker-compose.yml`, which will require a fresh build before the game will run.

```bash
docker-compose down --rmi local
```

## Known Issues and Troubleshooting

This environment is viable for local development or demonstration, but is **not** safe for production use due to easily-guessable default credentials.

### Port Collisions

The included `docker-compose.yml` attempts to listen on the following ports, and will exhibit errors or other bad behavior if they are already in use:

- 3000 (Grafana)
- 4000 (ExVenture)
- 5555 (ExVenture)
- 9090 (Prometheus)
- 15432 (PostgreSQL)

[compose-file]: https://docs.docker.com/compose/compose-file/
[docker]: https://www.docker.com/why-docker
[docker-compose]: https://docs.docker.com/compose/overview/
[docker-for-mac]: https://docs.docker.com/docker-for-mac/install/
[grafana]: https://grafana.com/
[midmud]: https://midmud.com/
[postgres_exporter]: https://github.com/wrouesnel/postgres_exporter
[postgresql]: https://www.postgresql.org/
[prometheus]: https://prometheus.io/docs/introduction/overview/
