## Deployment

### Configuration

Before you generate a production release, you need to set up your `config/prod.secret.exs` file

```elixir
use Mix.Config

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "fill me in",
  hostname: "fill me in",
  port: "5432",
  ssl: true,
  username: "fill me in",
  password: "fill me in",
  pool_size: 20

config :gossip, :client_id, "fill me in"
config :gossip, :client_secret, "fill me in"

config :pid_file, file: "/home/user/ex_venture.pid"
```

Other configuration you may want to include in this file is cluster configuration (if you're clustering) and Sentry configuration to get error reporting.

You also need several environment variables to be present when the server is running. A simple way of doing this is adding the following to `/etc/profile.d/game.sh`, so they are sourced when logging in.

```bash
export HOST="fill me in"

export HTTP_PORT="443"
export HTTP_SCHEME="https"

export SMTP_SERVER="fill me in"
export SMTP_PORT="fill me in"
export SMTP_USERNAME="fill me in"
export SMTP_PASSWORD="fill me in"

export EXVENTURE_MAILER_FROM="fill me in"
```

### Generating a release

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
