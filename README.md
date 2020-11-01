# ExVenture

[![Discord](https://img.shields.io/badge/chat-discord-7289da.svg)][discord]
[![Patreon](https://img.shields.io/badge/support-patreon-F96854.svg)](https://www.patreon.com/ericoestrich)

A text based MMO server written in Elixir.

- [Support ExVenture on Patreon](https://www.patreon.com/ericoestrich)
- [Chat with us on Discord][discord]

## Requirements

- PostgreSQL 12+
- Elixir 1.10+
- Erlang 22+
- node.js 12+

## Setup

```bash
mix deps.get
npm install -g yarn
(cd assets && yarn install)
mix ecto.reset
mix phx.server
```

## Running Tests

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

## Docker locally

Docker is set up as a replication of production. This generates an erlang release and is not intended for development purposes.

```bash
docker-compose pull
docker-compose build
docker-compose up -d postgres
docker-compose run --rm app eval "ExVenture.ReleaseTasks.Migrate.run()"
docker-compose up app
```

You now can view `http://localhost:4000` and access the application.

[discord]: https://discord.gg/GPEa6dB
