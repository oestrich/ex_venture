defmodule Game.Command.Examine do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  alias Game.Items

  commands(["examine"])

  @impl Game.Command
  def help(:topic), do: "Examine"
  def help(:short), do: "View information about items in your inventory"

  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {command}examine short sword{/command}
    """
  end

  @impl Game.Command
  @doc """
  View information about items in your inventory
  """
  def run(command, state)

  def run({item_name}, %{socket: socket, save: save}) do
    %{wearing: wearing, wielding: wielding, items: items} = save

    wearing_instances = Enum.map(wearing, &elem(&1, 1))
    wielding_instances = Enum.map(wielding, &elem(&1, 1))

    items = Items.items(wearing_instances ++ wielding_instances ++ items)

    case Enum.find(items, &Game.Item.matches_lookup?(&1, item_name)) do
      nil -> nil
      item -> socket |> @socket.echo(Format.item(item))
    end

    :ok
  end

  def run({}, %{socket: socket}) do
    socket
    |> @socket.echo(
      "You don't know what to examine. See {command}help examine{/command} for more information."
    )

    :ok
  end
end
