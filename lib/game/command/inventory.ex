defmodule Game.Command.Inventory do
  @moduledoc """
  The "inventory" command
  """

  use Game.Command

  alias Game.Items

  @commands ["inventory"]
  @aliases ["inv"]

  @short_help "View your character's inventory"
  @full_help """
  Example: inventory
  Alias: `inv`
  """

  @doc """
  Look at your inventory
  """
  @spec run([], session :: Session.t, state :: map) :: :ok
  def run([], _session, %{socket: socket, save: %{item_ids: item_ids}}) do
    items = Items.items(item_ids)
    socket |> @socket.echo(Format.inventory(items))
    :ok
  end
end
