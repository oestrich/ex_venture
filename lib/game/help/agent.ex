defmodule Game.Help.Agent do
  @moduledoc """
  Agent for holding cached help topics

  To reduce database loading
  """

  use GenServer

  alias Game.Help.BuiltIn
  alias Game.Help.Repo

  @key :help_topics

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def all(ids) do
    ids
    |> Enum.map(&get/1)
    |> Enum.map(fn
      {:ok, help} -> help
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  def get(id) do
    case Cachex.get(@key, id) do
      {:ok, help} ->
        {:ok, help}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Get all cached built in topics
  """
  def built_ins() do
    case Cachex.keys(@key) do
      {:ok, keys} ->
        keys
        |> Enum.filter(&(elem(&1, 0) == :built_in))
        |> all()

      _ ->
        []
    end
  end

  @doc """
  Get all cached help topics
  """
  def topics() do
    case Cachex.keys(@key) do
      {:ok, keys} ->
        keys
        |> Enum.filter(&(elem(&1, 0) == :topic))
        |> all()

      _ ->
        []
    end
  end

  @doc """
  Insert a new help topic into the loaded data
  """
  @spec insert(Skill.t()) :: :ok
  def insert(topic) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, topic})
    end)
  end

  @doc """
  Trigger an help topic reload
  """
  @spec reload(Skill.t()) :: :ok
  def reload(topic), do: insert(topic)

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  #
  # Server
  #

  def init(_) do
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())

    {:ok, %{}, {:continue, {:load_help}}}
  end

  def handle_continue({:load_help}, state) do
    Enum.each(Repo.all(), fn help ->
      Cachex.put(@key, {:topic, help.id}, help)
    end)

    reload_built_ins()

    {:noreply, state}
  end

  def handle_call({:insert, topic}, _from, state) do
    Cachex.put(@key, {:topic, topic.id}, topic)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)
    reload_built_ins()

    {:reply, :ok, state}
  end

  defp reload_built_ins() do
    Enum.each(built_in(), fn built_in ->
      Cachex.put(@key, {:built_in, built_in.id}, built_in)
    end)
  end

  defp built_in() do
    path = Path.join(:code.priv_dir(:ex_venture), "help/en.yml")
    {:ok, help_from_file} = YamlElixir.read_from_file(path)

    Enum.map(help_from_file, fn help ->
      help = for {key, val} <- help, into: %{}, do: {String.to_atom(key), val}
      help = help |> Enum.into(%{})
      struct(BuiltIn, help)
    end)
  end
end
