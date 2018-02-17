defmodule Game.Help.Agent do
  @moduledoc """
  Agent for holding cached help topics

  To reduce database loading
  """

  alias Game.Help.BuiltIn
  alias Game.Help.Repo

  def start_link() do
    Agent.start_link(fn -> _all() end, name: __MODULE__)
  end

  @doc """
  Test only. Allow tests to reset to the default help
  """
  def reset() do
    Agent.update(__MODULE__, fn _ -> _all() end)
  end

  defp _all() do
    %{
      database: Repo.all(),
      built_in: _built_in()
    }
  end

  defp _built_in() do
    :ex_venture
    |> :code.priv_dir()
    |> Path.join("help/en.yml")
    |> YamlElixir.read_from_file()
    |> Enum.map(fn help ->
      help = for {key, val} <- help, into: %{}, do: {String.to_atom(key), val}
      help = help |> Enum.into(%{})
      struct(BuiltIn, help)
    end)
  end

  @doc """
  Get all help topics in the agent
  """
  def database() do
    Agent.get(__MODULE__, fn help -> Map.get(help, :database, []) end)
  end

  @doc """
  Get the built in help files from the agent
  """
  def built_in() do
    Agent.get(__MODULE__, fn help -> Map.get(help, :built_in, []) end)
  end

  @doc """
  Add a newly added topic to the agent
  """
  def add(help_topic) do
    Agent.update(__MODULE__, fn help ->
      %{help | database: [help_topic | help.database]}
    end)
  end

  @doc """
  Update a help topic already in the agent
  """
  def update(help_topic) do
    Agent.update(__MODULE__, fn help ->
      topics = Enum.reject(help.database, &(&1.id == help_topic.id))
      %{help | database: [help_topic | topics]}
    end)
  end
end
