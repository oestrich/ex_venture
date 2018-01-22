defmodule Game.Command.Inventory do
  @moduledoc """
  The "inventory" command
  """

  use Game.Command

  alias Game.Items

  commands [{"inventory", ["inv", "i"]}]

  @impl Game.Command
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
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)
  def run({}, state = %{save: %{currency: currency, wearing: wearing, wielding: wielding, items: items}}) do
    wearing = wearing
    |> Enum.reduce(%{}, fn ({slot, instance}, wearing) ->
      Map.put(wearing, slot, Items.item(instance))
    end)

    wielding = wielding
    |> Enum.reduce(%{}, fn ({hand, instance}, wielding) ->
      Map.put(wielding, hand, Items.item(instance))
    end)

    items =
      items
      |> Items.items()
      |> Enum.reduce(%{}, fn (item, map) ->
        %{quantity: quantity} = Map.get(map, item.id, %{item: item, quantity: 0})
        Map.put(map, item.id, %{item: item, quantity: quantity + 1})
      end)
      |> Map.values()

    {:paginate, Format.inventory(currency, wearing, wielding, items), state}
  end
end
