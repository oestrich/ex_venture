defmodule Game.Command.Inventory do
  @moduledoc """
  The "inventory" command
  """

  use Game.Command

  alias Game.Items

  commands([{"inventory", ["inv", "i"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Inventory"
  def help(:short), do: "View your character's inventory"

  def help(:full) do
    """
    View your inventory.

    Listed will be items you are wielding, wearing, and holding.

    Example:
    [ ] > {command}inventory{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Inventory.parse("inventory")
      {}
      iex> Game.Command.Inventory.parse("inv")
      {}
      iex> Game.Command.Inventory.parse("i")
      {}

      iex> Game.Command.Inventory.parse("inventory extra")
      {:error, :bad_parse, "inventory extra"}

      iex> Game.Command.Inventory.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("i"), do: {}
  def parse("inv"), do: {}
  def parse("inventory"), do: {}

  @impl Game.Command
  @doc """
  Look at your inventory
  """
  def run(command, state)

  def run({}, state = %{save: save}) do
    %{currency: currency, wearing: wearing, wielding: wielding, items: items} = save

    wearing =
      wearing
      |> Enum.reduce(%{}, fn {slot, instance}, wearing ->
        Map.put(wearing, slot, Items.item(instance))
      end)

    wielding =
      wielding
      |> Enum.reduce(%{}, fn {hand, instance}, wielding ->
        Map.put(wielding, hand, Items.item(instance))
      end)

    items =
      items
      |> Items.items()
      |> Enum.reduce(%{}, fn item, map ->
        %{quantity: quantity} = Map.get(map, item.id, %{item: item, quantity: 0})
        Map.put(map, item.id, %{item: item, quantity: quantity + 1})
      end)
      |> Map.values()

    {:paginate, Format.inventory(currency, wearing, wielding, items), state}
  end
end
