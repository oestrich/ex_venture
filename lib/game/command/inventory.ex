defmodule Game.Command.Inventory do
  @moduledoc """
  The "inventory" command
  """

  use Game.Command

  alias Game.Items

  commands [{"inventory", ["inv", "i"]}]

  def help(:topic), do: "Inventory"
  def help(:short), do: "View your character's inventory"
  def help(:full) do
    """
    View your inventory.

    Listed will be items you are wielding, wearing, and holding.

    Example:
    [ ] > {white}inventory{/white}
    """
  end

  @doc """
  Look at your inventory
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, state = %{save: %{currency: currency, wearing: wearing, wielding: wielding, item_ids: item_ids}}) do
    wearing = wearing
    |> Enum.reduce(%{}, fn ({slot, item_id}, wearing) ->
      Map.put(wearing, slot, Items.item(item_id))
    end)

    wielding = wielding
    |> Enum.reduce(%{}, fn ({hand, item_id}, wielding) ->
      Map.put(wielding, hand, Items.item(item_id))
    end)

    items = Items.items(item_ids)

    {:paginate, Format.inventory(currency, wearing, wielding, items), state}
  end
end
