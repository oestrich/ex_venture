defmodule Game.ColorCodes do
  @moduledoc """
  GenServer to keep track of color_codes in the game.

  Stores them in an ETS table
  """

  use GenServer

  alias Data.ColorCode
  alias Data.Repo

  @key :color_codes

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get all color codes that are cached
  """
  @spec all() :: [ColorCode.t()]
  def all() do
    case Cachex.keys(@key) do
      {:ok, keys} ->
        keys
        |> Enum.map(&all_get/1)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  end

  defp all_get(key) do
    case get(key) do
      {:ok, key} ->
        key

      _ ->
        nil
    end
  end

  @spec get(integer() | String.t()) :: ColorCode.t() | nil
  def get(key) when is_binary(key) do
    case Cachex.get(@key, key) do
      {:ok, color_code} when color_code != nil ->
        {:ok, color_code}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Insert a new color_code into the loaded data
  """
  @spec insert(ColorCode.t()) :: :ok
  def insert(color_code) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, color_code})
    end)
  end

  @doc """
  Trigger an color_code reload
  """
  @spec reload(ColorCode.t()) :: :ok
  def reload(color_code), do: insert(color_code)

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

    GenServer.cast(self(), :load_color_codes)

    {:ok, %{}}
  end

  def handle_cast(:load_color_codes, state) do
    color_codes = ColorCode |> Repo.all()

    Enum.each(color_codes, fn color_code ->
      Cachex.put(@key, color_code.key, color_code)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, color_code}, _from, state) do
    Cachex.put(@key, color_code.key, color_code)

    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)

    {:reply, :ok, state}
  end
end
