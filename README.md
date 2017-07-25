# ExVenture

A MUD written in Elixir

## Setup

```bash
mix deps.get
mix compile
mix ecto.reset
mix run --no-halt
```

This will start a server on port 5555 that you can connect with using the `local.tin` tintin++ config.
