defmodule Game.Items do
  @moduledoc """
  Agent for keeping track of items in the system
  """

  alias Data.Item
  alias Data.Repo

  @doc false
  def start_link() do
    Agent.start_link(&load_items/0, name: __MODULE__)
  end

  defp load_items() do
    Enum.reduce(Item |> Repo.all, %{}, fn (item, map) ->
      Map.put(map, item.id, item)
    end)
  end

  @spec item(id :: integer) :: Item.t | nil
  def item(id) do
    Agent.get(__MODULE__, &(Map.get(&1, id, nil)))
  end

  @spec items(ids :: [integer]) :: [Item.t]
  def items(ids) do
    Agent.get(__MODULE__, fn (items) ->
      ids
      |> Enum.map(fn (id) -> Map.get(items, id, nil) end)
      |> Enum.reject(&is_nil/1)
    end)
  end

  @doc """
  Insert a new item into the loaded data
  """
  @spec insert(item :: Item.t) :: :ok
  def insert(item) do
    Agent.update(__MODULE__, fn (items) ->
      Map.put(items, item.id, item)
    end)
  end

  @doc """
  Trigger an item reload
  """
  @spec reload(item :: Item.t) :: :ok
  def reload(item), do: insert(item)
end
