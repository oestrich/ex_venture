defmodule Game.Command.Drop do
  @moduledoc """
  The "drop" command
  """

  use Game.Command

  alias Game.Items

  @commands ["drop"]
  @must_be_alive true

  @short_help "Drop an item in the same room"
  @full_help """
  Example: drop sword
  """

  @doc """
  #{@short_help}
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok | {:update, map}
  def run(command, session, state)
  def run({item_name}, _session, state = %{socket: socket, save: %{item_ids: item_ids}}) do
    items = Items.items(item_ids)
    case Enum.find(items, &(Game.Item.matches_lookup?(&1, item_name))) do
      nil ->
        socket |> @socket.echo(~s(Could not find "#{item_name}"))
        :ok
      item -> drop(item, state)
    end
  end

  def drop(item, state = %{socket: socket, save: save}) do
    save = %{save | item_ids: List.delete(save.item_ids, item.id)}
    socket |> @socket.echo("You dropped #{item.name}")
    @room.drop(save.room_id, item)
    {:update, Map.put(state, :save, save)}
  end
end
