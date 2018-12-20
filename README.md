# ExVenture

[![Trello](https://img.shields.io/badge/issues-trello-blue.svg)](https://trello.com/b/PFGmFWmu/exventure)
[![Discord](https://img.shields.io/badge/chat-discord-7289da.svg)][discord]
[![Patreon](https://img.shields.io/badge/support-patreon-F96854.svg)](https://www.patreon.com/exventure)

<img src="https://exventure.org/images/exventure.png" alt="ExVenture Logo" width="200" />

A text based MMO server written in Elixir.

- [Documentation for Admins](https://exventure.org/)
- [Support ExVenture on Patreon](https://www.patreon.com/exventure)
- [Trello Issues](https://trello.com/b/PFGmFWmu/exventure)
- [Chat with us on Discord][discord]
- [Support and Development Forums](https://forums.exventure.org/)

## Features

### Powerful web admin

- Everything is editable by the web admin panel and live in the game on save
- There are no text files to edit, everything is stored in PostgreSQL

### Web client

- Using Phoenix Channels, ExVenture ships with a built in web client
- Hosted by the app itself, accessible by browsing to `/play`

### Cross Game Chat

- ExVenture fully supports the [Gossip][gossip] network
- Supports [Grapevine][grapevine]
- Cross game channels
- Cross game tells

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

## Games Running ExVenture

If you are running an ExVenture MUD and want to get on this list, let us know on the [Discord][discord]!

- [MidMUD](https://midmud.com/)
- [Olympia MUD](https://olympia.exventure.world/)

## Requirements

- PostgreSQL 10
- Elixir 1.7.2
- Erlang 21.0.5
- node.js 8.6

## Setup

```bash
mix deps.get
mix compile
cd assets && npm install && node run build && cd ..
mix ecto.reset
mix run --no-halt
```

This will start a server on port 5555 that you can connect with using the `local.tin` tintin++ config. Ecto reset will include a sample area, classes, skills, and a login. You can also load [http://localhost:4000/](http://localhost:4000/) in your browser for the admin panel and web client.

## Running Tests

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
mix test
```

## Web Client

A web client is hosted by the game. Once it is running locally, you can access it via [http://localhost:4000/play](http://localhost:4000/play]).

![Web Client](https://exventure.org/images/web-client.png)

## Admin Panel

There is an admin panel located at [http://locahost:4000/admin](http://localhost:4000/admin) that you can build out the game in. Create zones, rooms, npcs, items, etc. in the panel. They will become live instantly on creating or updating.

You can see more on [exventure.org](https://exventure.org/admin/).

![Admin Dashboard](https://exventure.org/images/admin-dashboard.png?refresh=true)


## Deployment

See [exventure.org for deployment setup](https://exventure.org/deploy).

## Metrics

Prometheus metrics are set up and will be reported on `/metrics`. You may want to have nginx deny requests to this endpoint or whitelist it for IPs, etc.

[discord]: https://discord.gg/GPEa6dB
[gossip]: https://gossip.haus/
[grapevine]: https://grapevine.haus/
