defmodule Game.Command.PickUp do
  @moduledoc """
  The "pick up" command
  """

  use Game.Command

  @doc """
  Pick up an item from a room
  """
  @spec run([item :: String.t], session :: Session.t, state :: map) :: :ok | {:update, map}
  def run([item_name], _session, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)

    case Enum.find(room.items, &(Game.Item.matches_lookup?(&1, item_name))) do
      nil ->
        socket |> @socket.echo(~s("#{item_name}" could not be found))
        :ok
      item ->
        pick_up(item, room, state)
    end
  end

  def pick_up(item, room, state = %{socket: socket, save: save}) do
    case @room.pick_up(room.id, item) do
      {:ok, item} ->
        save = %{save | item_ids: [item.id | save.item_ids]}
        socket |> @socket.echo("You picked up the #{item.name}")
        {:update, Map.put(state, :save, save)}
      _ ->
        socket |> @socket.echo(~s("#{item.name}" could not be found))
        :ok
    end
  end
end
