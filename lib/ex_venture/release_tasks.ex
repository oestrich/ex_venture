# From https://github.com/bitwalker/distillery/blob/master/docs/Running%20Migrations.md
defmodule ExVenture.ReleaseTasks do
  @moduledoc false

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  @apps [
    :ex_venture
  ]

  @repos [
    Data.Repo
  ]

  def migrate() do
    startup()

    # Run migrations
    Enum.each(@apps, &run_migrations_for/1)

    # Signal shutdown
    IO.puts("Success!")
    :init.stop()
  end

  def seed do
    startup()

    Game.Config.start_link([name: Game.Config])

    # Run the seed script if it exists
    seed_script = Path.join([priv_dir(:ex_venture), "repo", "seeds.exs"])

    if File.exists?(seed_script) do
      IO.puts("Running seed script..")
      Code.eval_file(seed_script)
    end

    # Signal shutdown
    IO.puts("Success!")
    :init.stop()
  end

  defp startup() do
    IO.puts("Loading ex_venture...")

    # Load the code for ex_venture, but don't start it
    Application.load(:ex_venture)

    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for ex_venture
    IO.puts("Starting repos..")
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts("Running migrations for #{app}")
    Ecto.Migrator.run(Data.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
end
