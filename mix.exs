defmodule ExVenture.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_venture,
      version: "0.10.0",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      aliases: aliases(),
      source_url: "https://github.com/oestrich/ex_venture",
      docs: [
        main: "readme",
        extras: ["README.md"],
      ],
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {ExVenture.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:comeonin, "~> 3.2"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:distillery, "~> 1.4", runtime: false},
      {:ecto, "~> 2.1"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:poison, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:ranch, "~> 1.4"},
      {:timex, "~> 3.1"},
      {:yaml_elixir, "~> 1.3"},
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
    ]
  end
end
