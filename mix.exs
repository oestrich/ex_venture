defmodule ExVenture.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_venture,
      version: "0.27.0",
      elixir: "~> 1.7.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      deps: deps(),
      aliases: aliases(),
      source_url: "https://github.com/oestrich/ex_venture",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger], mod: {ExVenture.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:bamboo, "~> 1.0"},
      {:bamboo_smtp, "~> 1.5"},
      {:bcrypt_elixir, "~> 1.0"},
      {:cachex, "~> 3.0"},
      {:comeonin, "~> 4.0"},
      {:cors_plug, "~> 1.5"},
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:distillery, "~> 2.0", runtime: false},
      {:earmark, "~> 1.2.3"},
      {:ecto, "~> 2.1"},
      {:elixir_uuid, "~> 1.2"},
      {:eqrcode, "~> 0.1.5"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:gettext, "~> 0.16.0"},
      {:gossip, "~> 1.0"},
      {:libcluster, "~> 3.0", only: [:dev, :prod]},
      {:logger_file_backend, "~> 0.0.10"},
      {:logster, "~> 0.4"},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_ecto, "~> 3.0"},
      {:phoenix_html, "~> 2.10"},
      {:pid_file, "~> 0.1.0"},
      {:prometheus_ex, git: "https://github.com/deadtrickster/prometheus.ex.git", override: true},
      {:prometheus_plugs, "~> 1.1"},
      {:poison, "~> 3.1"},
      {:pot, git: "https://github.com/yuce/pot.git"},
      {:postgrex, ">= 0.0.0"},
      {:oauth2, "~> 0.9"},
      {:ranch, "~> 1.5.0"},
      {:sentry, "~> 6.2"},
      {:squabble, git: "https://github.com/oestrich/squabble.git"},
      {:timex, "~> 3.1"},
      {:ueberauth, "~> 0.4"},
      {:yaml_elixir, "~> 2.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate.reset": ["ecto.drop", "ecto.create", "ecto.migrate"]
    ]
  end
end
