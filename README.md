# ExVenture

[![Build Status](https://travis-ci.org/oestrich/ex_venture.svg?branch=master)](https://travis-ci.org/oestrich/ex_venture)

A MUD written in Elixir

## Setup

```bash
mix deps.get
mix compile
mix ecto.reset
cd assets && npm install && node node_modules/brunch/bin/brunch build && cd ..
mix run --no-halt
```

This will start a server on port 5555 that you can connect with using the `local.tin` tintin++ config. Ecto reset will include a sample area, classes, skills, and a login.

## Deployment

Distillery is used to generate releases. Once a release is generated you can copy the tar file to the server and start it up.

```bash
cd assets && node node_modules/brunch/bin/brunch build && cd ..
MIX_ENV=prod mix compile
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix release
```

The `release.sh` script will also do the same.

## Documentation

You can get elixir docs by running `mix docs` and open `doc/index.html`. The code base has a lot of doctests to help give examples of how to use the functions.
