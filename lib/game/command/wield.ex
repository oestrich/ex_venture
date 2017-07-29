defmodule Game.Command.Wield do
  @moduledoc """
  The "wield" command
  """

  use Game.Command

  alias Game.Item
  alias Game.Items

  @commands ["wield"]

  @short_help "Put an item in your hands"
  @full_help """
  Example: wield
  """

  @doc """
  Put an item in your hands
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run([item_name], _session, state = %{socket: socket, save: %{item_ids: item_ids}}) do
    items = Items.items(item_ids)
    case Item.find_item(items, item_name) do
      nil ->
        socket |> @socket.echo(~s("#{item_name}" could not be found."))
        :ok
      item ->
        socket |> @socket.echo(~s(#{item.name} is now in your right hand.))
        %{save: save} = state
        save = %{save | item_ids: List.delete(item_ids, item.id), wielding: %{right: item.id}}
        {:update, Map.put(state, :save, save)}
    end
  end
end
