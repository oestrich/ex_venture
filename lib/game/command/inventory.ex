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
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, save: %{wearing: wearing, wielding: wielding, item_ids: item_ids}}) do
    wearing = wearing
    |> Enum.reduce(%{}, fn ({hand, item_id}, wearing) ->
      Map.put(wearing, hand, Items.item(item_id))
    end)

    wielding = wielding
    |> Enum.reduce(%{}, fn ({hand, item_id}, wielding) ->
      Map.put(wielding, hand, Items.item(item_id))
    end)

    items = Items.items(item_ids)
    socket |> @socket.echo(Format.inventory(wearing, wielding, items))
    :ok
  end
end
