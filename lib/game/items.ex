defmodule Game.Items do
  @moduledoc """
  Agent for keeping track of items in the system
  """

  use GenServer

  import Ecto.Query

  alias Data.Item
  alias Data.Repo

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec item(integer()) :: Item.t() | nil
  def item(instance = %Item.Instance{}) do
    item(instance.id)
  end

  def item(id) when is_integer(id) do
    case Cachex.get(:items, id) do
      {:ok, item} when item != nil -> item
      _ -> nil
    end
  end

  @spec items([Item.instance()]) :: [Item.t()]
  def items(instances) do
    instances
    |> Enum.map(&item/1)
    |> Enum.reject(&is_nil/1)
  end

  @spec items_keep_instance([Item.instance()]) :: [{Item.instance(), Item.t()}]
  def items_keep_instance(instances) do
    instances
    |> Enum.map(fn instance ->
      {instance, item(instance)}
    end)
    |> Enum.reject(fn {_, item} ->
      is_nil(item)
    end)
  end

  @doc """
  Insert a new item into the loaded data
  """
  @spec insert(Item.t()) :: :ok
  def insert(item) do
    GenServer.call(__MODULE__, {:insert, item})
  end

  @doc """
  Trigger an item reload
  """
  @spec reload(Item.t()) :: :ok
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
    GenServer.cast(self(), :load_items)
    {:ok, %{}}
  end

  def handle_cast(:load_items, state) do
    items =
      Item
      |> preload([:item_aspects])
      |> Repo.all()

    Enum.each(items, fn item ->
      item = Item.compile(item)
      Cachex.set(:items, item.id, item)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, item = %Item{}}, _from, state) do
    item =
      item
      |> Repo.preload([:item_aspects])
      |> Item.compile()

    Cachex.set(:items, item.id, item)
    {:reply, :ok, state}
  end

  def handle_call({:insert, item}, _from, state) do
    Cachex.set(:items, item.id, item)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(:items)

    {:reply, :ok, state}
  end
end
