defmodule Game.Command.Drop do
  @moduledoc """
  The "drop" command
  """

  use Game.Command
  use Game.Currency

  alias Game.Environment
  alias Game.Item
  alias Game.Items

  @must_be_alive true

  commands(["drop"])

  @impl Game.Command
  def help(:topic), do: "Drop"
  def help(:short), do: "Drop an item in the same room"

  def help(:full) do
    """
    Drop an item into the room you are in.

    Example:
    [ ] > {command}drop sword{/command}
    [ ] > {command}drop 10 gold{/command}
    """
  end

  @impl Game.Command
  @doc """
  Drop an item in the same room
  """
  def run(command, state)

  def run({item_name}, state) do
    case Environment.room_type(state.save.room_id) do
      :room ->
        drop(state, item_name)

      :overworld ->
        state.socket |> @socket.echo("You cannot drop items in the overworld.")
    end
  end

  def run({}, %{socket: socket}) do
    message =
      "Please provide an item to drop. See {command}help drop{/command} for more information."

    socket |> @socket.echo(message)
  end

  defp drop(state, item_name) do
    case Regex.match?(~r{#{@currency}}, item_name) do
      true ->
        drop_currency(item_name, state)

      false ->
        drop_item(item_name, state)
    end
  end

  defp drop_currency(amount_to_drop, state = %{socket: socket, save: %{currency: currency}}) do
    amount =
      amount_to_drop
      |> String.split(" ")
      |> List.first()
      |> String.to_integer()

    case currency - amount >= 0 do
      true ->
        _drop_currency(amount, state)

      false ->
        socket |> @socket.echo("You do not have enough #{currency()} to drop #{amount}.")
    end
  end

  defp _drop_currency(amount, state = %{socket: socket, save: %{currency: currency}}) do
    save = %{state.save | currency: currency - amount}
    socket |> @socket.echo("You dropped #{amount} #{currency()}.")
    @environment.drop_currency(save.room_id, {:user, state.user}, amount)

    {:update, Map.put(state, :save, save)}
  end

  defp drop_item(item_name, state = %{socket: socket, save: %{items: items}}) do
    items = Items.items(items)

    case Enum.find(items, &Item.matches_lookup?(&1, item_name)) do
      nil ->
        socket |> @socket.echo(~s(Could not find "#{item_name}".))

      item ->
        _drop_item(item, state)
    end
  end

  defp _drop_item(item, state = %{socket: socket, user: user, save: save}) do
    {instance, items} = Item.remove(save.items, item)
    save = %{save | items: items}
    @environment.drop(save.room_id, {:user, user}, instance)

    socket |> @socket.echo("You dropped #{Format.item_name(item)}.")

    {:update, Map.put(state, :save, save)}
  end
end
