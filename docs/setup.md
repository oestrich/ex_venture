# Setup

By the end of this guide you should have a working ExVenture development environment.

## Requirements

### Git

You should install Git via your platform's package manager.

### PostgreSQL

You should install PostgreSQL via your platforms package manager or Postgres.app for Mac.

Ubuntu:

```bash
sudo apt install postgresql
```

For Arch, following the [wiki on installing PostgreSQL][arch-wiki-pg].

#### Create a User

Create a PostgreSQL user that has a password with the following command. This will make a PostgreSQL user with the same name as your login user. It will also attach a password to this account, don't forget it as you will need it later on.

```bash
sudo -u postgres createuser -P --superuser `whoami`
```

#### PostgreSQL Authentication

Set up a `config/dev.local.exs` file. This does not exist so you will need to make it. Place the following inside of it, change the username and password to match what you picked above.

```elixir
use Mix.Config

config :ex_venture, Data.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_venture_dev",
  hostname: "localhost",
  username: "CHANGEME",
  password: "CHANGEME",
  pool_size: 10
```

### Elixir / Erlang

The easiest way to get Erlang/Elixir going is to install [asdf][asdf]. You can follow their install guide on the [README][asdf-install]. Below is the Ubuntu bash set up for reference.

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.4.0
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
```

After installing asdf make sure to reload your terminal by opening a new tab or sourcing your bashrc file again, `source ~/.bashrc`.

Before installing Elixir you need to install Erlang. It may also require development headers to be in place depending on your system.

Ubuntu ([taken from asdf-erlang][asdf-erlang]):

```bash
sudo apt install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-dev libgl1-mesa-dev libglu1-mesa-dev libpng3 libssh-dev unixodbc-dev
```

Install Erlang via [asdf][asdf-erlang].

```bash
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang 21.0.2
asdf global erlang 21.0.2
```

Install Elixir via [asdf][asdf-elixir].

```bash
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir 1.6.6
asdf global elixir 1.6.6
mix local.hex
mix local.rebar
```

### node.js

Install node.js via [asdf][asdf-nodejs].

```bash
asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
asdf install nodejs 8.6.0
asdf global nodejs 8.6.0
```

You will also need python for node-sass:

Ubuntu

```bash
sudo apt install python
```

## ExVenture

With requirements set up we can start to get ExVenture going. These commands will set up the elixir side:

```bash
git clone git@github.com:oestrich/ex_venture.git
cd ex_venture
mix deps.get
mix compile
```

To get assets set up, which uses [brunch][brunch]:

```bash
cd assets
npm install
node node_modules/brunch/bin/brunch build
cd ..
```

Next get the database set up:

```bash
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

With that the app is up and running. You can boot it with:

```bash
mix run --no-halt
```

And connect via telnet on 5555 and via web on 4000. Both of these are configurable via the file `config/dev.exs`.

If you have [tintin++][tt++] installed you can connect with:

```bash
tt++ -G local.tin
```

The `local.tin` tintin script sets up base GMCP and can turn debug mode on my removing a `nop` on `config {debug telnet} {on}`.

### Tests

To run tests you need to set up the test database first:

```bash
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
```

Once that is in place you can run tests with:

```bash
mix test
```

[pg.app]: https://postgresapp.com/
[arch-wiki-pg]: https://wiki.archlinux.org/index.php/PostgreSQL#Installing_PostgreSQL
[asdf]: https://github.com/asdf-vm/asdf
[asdf-install]: https://github.com/asdf-vm/asdf#setup
[asdf-erlang]: https://github.com/asdf-vm/asdf-erlang
[asdf-elixir]: https://github.com/asdf-vm/asdf-elixir
[asdf-nodejs]: https://github.com/asdf-vm/asdf-nodejs
[brunch]: https://github.com/brunch/brunch
[tt++]: http://tintin.sourceforge.net/
