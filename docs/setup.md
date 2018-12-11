# Setup

By the end of this guide you should have a working ExVenture development environment. We need to install PostgreSQL and several programming languages that are used by ExVenture.

## Requirements

### Git

You should install Git via your platform's package manager.

Ubuntu:

```bash
sudo apt install git
```

### Cloning ExVenture

Clone ExVenture.

```bash
git clone https://github.com/oestrich/ex_venture.git
cd ex_venture
```

### PostgreSQL

You should install PostgreSQL via your platforms package manager or Postgres.app for Mac.

Make sure this is PostgreSQL 10+, older versions will not work with ExVenture.

Ubuntu:

```bash
sudo apt install postgresql
```

#### Create a User

Create a PostgreSQL user that has a password with the following command. This will make a PostgreSQL user with the same name as your login user. It will also attach a password to this account, don't forget it as you will need it later on.

```bash
sudo -u postgres createuser -P --superuser `whoami`
```

#### PostgreSQL Authentication

Set up a `config/dev.local.exs` file. This does not exist so you will need to make it. Place the following inside of it, change the username and password to match what you picked above. The username will be your local username, type `whoami` to see it.

```elixir
use Mix.Config

config :ex_venture, Data.Repo,
  database: "ex_venture_dev",
  hostname: "localhost",
  username: "CHANGEME",
  password: "CHANGEME",
  pool_size: 10
```

### Elixir / Erlang / Node.js

The easiest way to get Erlang/Elixir and Node.js going is to install [asdf][asdf]. asdf is a tool that manages programming language versions. It will simply getting and staying on the correct versions required for running ExVenture.

You can follow their install guide on the [README][asdf-install]. Below is the Ubuntu bash set up for reference.

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.5.1
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
```

After installing asdf make sure to reload your terminal by opening a new tab or sourcing your bashrc file again, `source ~/.bashrc`.

Before installing Erlang you may also require development headers to be in place depending on your system. Node also requires python for `node-sass`.

Ubuntu ([taken from asdf-erlang][asdf-erlang]):

```bash
sudo apt install build-essential autoconf m4 libncurses5-dev libssh-dev unixodbc-dev python unzip
```

Install the nodejs plugin first to source their keyring.

```bash
asdf plugin-add nodejs
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
```

Install all three languages. This will take a while. You may need to run `asdf install` three times to get all of the languages installed.

```bash
asdf plugin-add erlang
asdf plugin-add elixir
asdf install
```

Get local versions of hex and rebar.

```bash
mix local.hex
mix local.rebar
```

Note that you _must_ install the versions in the `.tool-versions` file. ExVenture stays very up to date with Erlang/Elixir versions and regularly uses features that require the latest version of Erlang or Elixir.

## ExVenture

With requirements set up we can start to get ExVenture going. These commands will set up the elixir side:

```bash
mix deps.get
mix compile
```

To get assets set up, which uses [webpack][webpack]. Webpack is a package that handles asset compilation for us.

```bash
cd assets
npm install
npm run build
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

And connect via telnet on 5555 and via web on 4000. Both of these are configurable via the file `config/dev.local.exs`.

If you have [tintin++][tt++] installed you can connect with:

```bash
tt++ -G local.tin
```

After connecting you will see:

```
ExVenture v0.23.0
Welcome to the MUD

What is your player name (Enter create for a new account)?
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
[webpack]: https://webpack.js.org/
[tt++]: http://tintin.sourceforge.net/
