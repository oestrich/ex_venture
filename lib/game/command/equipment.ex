defmodule Game.Command.Equipment do
  @moduledoc """
  The "equipment" command
  """

  use Game.Command

  alias Game.Items

  commands([{"equipment", ["eq"]}], parse: false)

  @impl Game.Command
  def help(:topic), do: "Equipment"
  def help(:short), do: "View your character's worn equipment"

  def help(:full) do
    """
    #{help(:short)}. Similar to inventory but
    will only display items worn and wielded.

    Example:
    [ ] > {white}equipment{/white}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Equipment.parse("equipment")
      {}
      iex> Game.Command.Equipment.parse("eq")
      {}

      iex> Game.Command.Equipment.parse("equipment hi")
      {:error, :bad_parse, "equipment hi"}

      iex> Game.Command.Equipment.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("eq"), do: {}
  def parse("equipment"), do: {}

  @impl Game.Command
  @doc """
  View your character's worn equipment
  """
  def run(command, state)

  def run({}, %{socket: socket, save: %{wearing: wearing, wielding: wielding}}) do
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

    socket |> @socket.echo(Format.equipment(wearing, wielding))
    :ok
  end
end
