defmodule Game.Room.Actions do
  @moduledoc """
  Actions that can happen in a room; pick up, tick, etc.
  """

  require Logger

  alias Game.Item
  alias Game.Items
  alias Game.Room
  alias Game.Room.Repo

  def pick_up(room, item) do
    case has_item?(room, item) do
      true -> _pick_up(room, item)
      false -> {room, :error}
    end
  end

  defp has_item?(room, item) do
    room.items |> Enum.any?(&(&1.id == item.id))
  end

  defp _pick_up(room, item) do
    {instance, items} = Item.remove(room.items, item)

    case Repo.update(room, %{items: items}) do
      {:ok, room} ->
        instance = Item.migrate_instance(instance)
        {room, {:ok, instance}}

      _ ->
        {room, :error}
    end
  end

  @doc """
  Pick up all of the currency in the room
  """
  @spec pick_up_currency(Room.t()) :: {Room.t(), {:ok, integer}}
  def pick_up_currency(room = %{currency: currency}) do
    case Repo.update(room, %{currency: 0}) do
      {:ok, room} -> {room, {:ok, currency}}
      _ -> {room, :error}
    end
  end

  @doc """
  Drop an item into a room
  """
  @spec drop(Room.t(), Item.instance()) :: {:ok, Room.t()}
  def drop(room, instance) do
    room |> Repo.update(%{items: [instance | room.items]})
  end

  @doc """
  Drop currency into a room
  """
  @spec drop_currency(Room.t(), integer) :: {:ok, Room.t()}
  def drop_currency(room, currency) do
    room |> Repo.update(%{currency: room.currency + currency})
  end

  @doc """
  Check to respawn items

  Spawns items if necessary
  """
  @spec maybe_respawn_items(State.t()) :: :ok | {:update, State.t()}
  def maybe_respawn_items(state = %{room: %{room_items: room_items}}) when length(room_items) > 0 do
    state = respawn_items(state)
    {:update, state}
  end

  def maybe_respawn_items(_), do: :ok

  defp respawn_items(state = %{room: room}) do
    room.room_items
    |> Enum.filter(&need_respawn?(&1, room))
    |> Enum.reduce(state, &respawn/2)
  end

  # Respawn only if the item is not present
  defp need_respawn?(room_item, room) do
    Enum.all?(room.items, &(&1.id != room_item.item_id))
  end

  defp respawn(room_item, state = %{respawn: respawn}) do
    case respawn[room_item.item_id] do
      nil -> start_respawn(room_item, state)
      _ -> state
    end
  end

  defp start_respawn(room_item, state = %{respawn: respawn}) do
    respawn = Map.put(respawn, room_item.item_id, Timex.now())
    :erlang.send_after(room_item.spawn_interval * 1000, self(), {:respawn, room_item.item_id})
    %{state | respawn: respawn}
  end

  def respawn_item(state = %{room: room, respawn: respawn}, item_id) do
    item = Items.item(item_id)
    instance = Data.Item.instantiate(item)

    case Repo.update(room, %{items: [instance | room.items]}) do
      {:ok, room} ->
        respawn = Map.delete(respawn, item_id)
        {:update, %{state | room: room, respawn: respawn}}

      {:error, _} ->
        :ok
    end
  end
end
