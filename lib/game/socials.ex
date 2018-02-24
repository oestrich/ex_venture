defmodule Game.Socials do
  @moduledoc """
  Agent for keeping track of socials in the system
  """

  use GenServer

  alias Data.Social
  alias Data.Repo

  @cache :socials

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec social(integer()) :: Social.t() | nil
  def social(instance = %Social{}) do
    social(instance.id)
  end

  def social(id) when is_integer(id) do
    _fetch_from_cache(@cache, id)
  end

  def social(command) when is_binary(command) do
    _fetch_from_cache(@cache, command)
  end

  @spec socials([integer()]) :: [Social.t()]
  def socials(ids) do
    ids
    |> Enum.map(&social/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Fetch all socials
  """
  @spec all() :: [Social.t()]
  def all() do
    Cachex.execute!(@cache, fn cache ->
      {:ok, keys} = Cachex.keys(cache)
      keys = Enum.filter(keys, &is_integer/1)
      socials =
        keys
        |> Enum.map(&_fetch_from_cache(cache, &1))
        |> Enum.reject(&is_nil/1)
      {:ok, socials}
    end)
  end

  defp _fetch_from_cache(cache, key) do
    case Cachex.get(cache, key) do
      {:ok, nil} -> nil
      {:ok, social} -> social
      _ -> nil
    end
  end

  @doc """
  Insert a new social into the loaded data
  """
  @spec insert(Social.t()) :: :ok
  def insert(social) do
    GenServer.call(__MODULE__, {:insert, social})
  end

  @doc """
  Trigger a social reload
  """
  @spec reload(Social.t()) :: :ok
  def reload(social), do: insert(social)

  @doc """
  Clean out an old command if it was updated
  """
  @spec remove_command(String.t()) :: :ok
  def remove_command(command) do
    GenServer.call(__MODULE__, {:remove_command, command})
  end

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    Cachex.clear(@cache)
  end

  #
  # Server
  #

  def init(_) do
    GenServer.cast(self(), :load_socials)
    {:ok, %{}}
  end

  def handle_cast(:load_socials, state) do
    socials = Social |> Repo.all()

    Enum.each(socials, fn social ->
      Cachex.set(@cache, social.id, social)
      Cachex.set(@cache, social.command, social)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, social}, _from, state) do
    Cachex.set(@cache, social.id, social)
    Cachex.set(@cache, social.command, social)

    {:reply, :ok, state}
  end

  def handle_call({:remove_command, command}, _from, state) do
    Cachex.del(@cache, command)

    {:reply, :ok, state}
  end
end
