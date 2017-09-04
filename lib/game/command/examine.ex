defmodule Game.Command.Examine do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  alias Game.Items

  @commands ["examine"]
  @aliases []

  @short_help "View information about items in your inventory"
  @full_help """
  Example: examine short sword
  """

  @doc """
  #{@short_help}
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({item_name}, _session, %{socket: socket, save: %{wearing: wearing, wielding: wielding, item_ids: item_ids}}) do
    wearing_ids = Enum.map(wearing, fn ({_, item_id}) -> item_id end)
    wielding_ids = Enum.map(wielding, fn ({_, item_id}) -> item_id end)

    items = Items.items(wearing_ids ++ wielding_ids ++ item_ids)
    case Enum.find(items, &(Game.Item.matches_lookup?(&1, item_name))) do
      nil -> nil
      item -> socket |> @socket.echo(Format.item(item))
    end
    :ok
  end
end
