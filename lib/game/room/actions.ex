defmodule Game.Room.Actions do
  @moduledoc """
  Actions that can happen in a room; pick up, tick, etc.
  """

  alias Game.Room.Repo

  def pick_up(room, item) do
    case item.id in room.item_ids do
      true -> _pick_up(room, item)
      false -> {room, :error}
    end
  end

  defp _pick_up(room, item) do
    case Repo.update(room, %{item_ids: List.delete(room.item_ids, item.id)}) do
      {:ok, room} -> {room, {:ok, item}}
      _ -> {room, :error}
    end
  end

  @doc """
  Handle a tick

  Spawns items if necessary
  """
  @spec tick(state :: map) :: :ok | {:update, Data.Room.t}
  def tick(state = %{room: %{room_items: room_items}}) when length(room_items) > 0 do
    state = respawn_items(state)
    {:update, state}
  end
  def tick(_), do: :ok

  defp respawn_items(state = %{room: room}) do
    room.room_items
    |> Enum.filter(&(need_respawn?(&1, room)))
    |> Enum.reduce(state, &respawn/2)
  end

  # Respawn only if the item is not present
  defp need_respawn?(room_item, room) do
    !(room_item.item_id in room.item_ids)
  end

  defp respawn(room_item, state = %{respawn: respawn}) do
    case respawn[room_item.item_id] do
      nil -> start_respawn(room_item, state)
      time -> respawn_if_after_interval(room_item, time, state)
    end
  end

  defp start_respawn(room_item, state = %{respawn: respawn}) do
    respawn = Map.put(respawn, room_item.item_id, Timex.now)
    %{state | respawn: respawn}
  end

  defp respawn_if_after_interval(room_item, time, state) do
    case past_interval?(time, room_item.interval) do
      true -> respawn_item(room_item, state)
      false -> state
    end
  end

  defp past_interval?(time, interval) do
    Timex.diff(Timex.now, time, :seconds) > interval
  end

  defp respawn_item(room_item, state = %{room: room, respawn: respawn}) do
    case Repo.update(room, %{item_ids: [room_item.item_id | room.item_ids]}) do
      {:ok, room} ->
        respawn = Map.delete(respawn, room_item.item_id)
        %{state | room: room, respawn: respawn}
      {:error, _} ->
        state
    end
  end
end
