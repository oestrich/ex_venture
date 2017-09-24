defmodule Game.Items do
  @moduledoc """
  Agent for keeping track of items in the system
  """

  use GenServer

  alias Data.Item
  alias Data.Repo

  @ets_table :items

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec item(id :: integer) :: Item.t | nil
  def item(id) do
    case :ets.lookup(@ets_table, id) do
      [{_, item}] -> item
      _ -> nil
    end
  end

  @spec items(ids :: [integer]) :: [Item.t]
  def items(ids) do
    ids
    |> Enum.map(fn (id) ->
      case :ets.lookup(@ets_table, id) do
        [{_, item}] -> item
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Insert a new item into the loaded data
  """
  @spec insert(item :: Item.t) :: :ok
  def insert(item) do
    GenServer.call(__MODULE__, {:insert, item})
  end

  @doc """
  Trigger an item reload
  """
  @spec reload(item :: Item.t) :: :ok
  def reload(item), do: insert(item)

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
    create_table()
    GenServer.cast(self(), :load_items)
    {:ok, %{}}
  end

  def handle_cast(:load_items, state) do
    items = Item |> Repo.all
    Enum.each(items, fn (item) ->
      :ets.insert(@ets_table, {item.id, item})
    end)
    {:noreply, state}
  end

  def handle_call({:insert, item}, _from, state) do
    :ets.insert(@ets_table, {item.id, item})
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete(@ets_table)
    create_table()

    {:reply, :ok, state}
  end

  defp create_table() do
    :ets.new(@ets_table, [:set, :protected, :named_table])
  end
end
