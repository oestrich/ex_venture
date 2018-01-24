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
  @spec pick_up_currency(Data.Room.t()) :: {Data.Room.t(), {:ok, integer}}
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
  Handle a tick

  Spawns items if necessary
  """
  @spec tick(map) :: :ok | {:update, Data.Room.t()}
  def tick(state = %{room: %{room_items: room_items}}) when length(room_items) > 0 do
    state = respawn_items(state)
    {:update, state}
  end

  def tick(_), do: :ok

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
      time -> respawn_if_after_interval(room_item, time, state)
    end
  end

  defp start_respawn(room_item, state = %{respawn: respawn}) do
    respawn = Map.put(respawn, room_item.item_id, Timex.now())
    %{state | respawn: respawn}
  end

  defp respawn_if_after_interval(room_item, time, state) do
    case past_interval?(time, room_item.spawn_interval) do
      true -> respawn_item(room_item, state)
      false -> state
    end
  end

  defp past_interval?(time, interval) do
    Timex.diff(Timex.now(), time, :seconds) > interval
  end

  defp respawn_item(room_item, state = %{room: room, respawn: respawn}) do
    item = Items.item(room_item.item_id)
    instance = Data.Item.instantiate(item)

    case Repo.update(room, %{items: [instance | room.items]}) do
      {:ok, room} ->
        respawn = Map.delete(respawn, room_item.item_id)
        %{state | room: room, respawn: respawn}

      {:error, _} ->
        state
    end
  end
end
