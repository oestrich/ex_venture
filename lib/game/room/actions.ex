defmodule Game.Room.Actions do
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
end
