# ExVenture

[![Trello](https://img.shields.io/badge/issues-trello-blue.svg)](https://trello.com/b/PFGmFWmu/exventure)
[![Discord](https://img.shields.io/badge/chat-discord-7289da.svg)](https://discord.gg/GPEa6dB)
[![Patreon](https://img.shields.io/badge/support-patreon-F96854.svg)](https://www.patreon.com/midmud)

A [MUD](https://en.wikipedia.org/wiki/MUD) (Multi-User Dungeon) written in Elixir.

![ExVenture Logo](https://exventure.org/images/exventure.png)

## Docs

[Elixir Docs](https://exventure.org/elixir/readme.html). [General usage docs](https://exventure.org/).

## Features

### Powerful web admin
- Everything is editable by the web admin panel and live in the game on save
- There are no text files to edit, everything is stored in PostgreSQL

### Web client
- Using Phoenix Channels, ExVenture ships with a built in web client
- Hosted by the app itself, accessible by browsing to `/play`

### Front Page
- News announcements
- Help is web accessible
- Classes, skills, and races are all available on the home page
- Send and receive in game mail from your account page
- Chat with players in the game from the web chat

### Security
- The telnet connection does _not_ allow passwords to be entered over plaintext
- Add TOTP to your account

### Resilient
- Crashes are contained in the room that they occur and those processes restart cleanly
- Player connections are _not_ dropped during session recovery

### Multi-node support
- Use the power of elixir to start a cluster for your game
- The world is spread across the entire cluster
- Building on local resiliency, the app will stay alive if a node goes down

## Requirements

- PostgreSQL 10
- Elixir 1.6
- Erlang 20
- node.js 8.6

## Setup

```bash
mix deps.get
mix compile
cd assets && npm install && node node_modules/brunch/bin/brunch build && cd ..
mix ecto.reset
mix run --no-halt
```

This will start a server on port 5555 that you can connect with using the `local.tin` tintin++ config. Ecto reset will include a sample area, classes, skills, and a login. You can also load [http://localhost:4000/](http://localhost:4000/) in your browser for the admin panel and web client.

## Running Tests

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
```

## Web Client

There is a web client located at [http://localhost:4000/play](http://localhost:4000/play]).

![Web Client](https://exventure.org/images/web-client.png)

## Admin Panel

There is an admin panel located at [http://locahost:4000/admin](http://localhost:4000/admin) that you can build out the game in. Create zones, rooms, npcs, items, etc. in the panel. They will become live instantly on creating or updating.

You can see more on [exventure.org](https://exventure.org/admin/).

![Admin Dashboard](https://exventure.org/images/admin-dashboard.png?refresh=true)

## Deployment

Distillery is used to generate releases. Once a release is generated you can copy the tar file to the server and start it up.

```bash
cd assets && node node_modules/brunch/bin/brunch build && cd ..
MIX_ENV=prod mix compile
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
```

The `release.sh` script will also do the same.

### TLS

The game does not support TLS natively, but you can get nginx to serve as a termination point and forward locally to the app. Nginx needs to be built with two modules, [stream_core](http://nginx.org/en/docs/stream/ngx_stream_core_module.html) and [stream_ssl](http://nginx.org/en/docs/stream/ngx_stream_ssl_module.html). You will also need to set the `ssl_port` option in networking. By default it will load from the `SSL_PORT` ENV variable.

```nginx
stream {
  upstream exventure {
    server 127.0.0.1:5555;
  }

  server {
    listen 5443 ssl;

    # Copy in your main site's settings here
    ssl_certificate /path/to/file.pem
    ssl_certificate_key /path/to/file.key

    proxy_pass exventure;
  }
}
```

## Metrics

Prometheus metrics are set up and will be reported on `/metrics`. You may want to have nginx deny requests to this endpoint or whitelist it for IPs, etc.
