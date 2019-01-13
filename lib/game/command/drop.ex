defmodule Game.Command.Drop do
  @moduledoc """
  The "drop" command
  """

  use Game.Command
  use Game.Currency

  alias Game.Environment
  alias Game.Item
  alias Game.Items
  alias Game.Player

  @must_be_alive true

  commands(["drop"])

  @impl Game.Command
  def help(:topic), do: "Drop"
  def help(:short), do: "Drop an item in the same room"

  def help(:full) do
    """
    Drop an item into the room you are in. You can drop an item in your inventory
    or some of your #{currency()} into the room.

    Example:
    [ ] > {command}drop sword{/command}
    [ ] > {command}drop 10 #{currency()}{/command}
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
        state |> Socket.echo(gettext("You cannot drop items in the overworld."))
    end
  end

  def run({}, state) do
    message =
      gettext(
        "Please provide an item to drop. See {command}help drop{/command} for more information."
      )

    state |> Socket.echo(message)
  end

  defp drop(state, item_name) do
    case Regex.match?(~r{#{@currency}}, item_name) do
      true ->
        drop_currency(item_name, state)

      false ->
        drop_item(item_name, state)
    end
  end

  defp drop_currency(amount_to_drop, state = %{save: %{currency: currency}}) do
    amount =
      amount_to_drop
      |> String.split(" ")
      |> List.first()
      |> String.to_integer()

    case currency - amount >= 0 do
      true ->
        _drop_currency(amount, state)

      false ->
        message =
          gettext("You do not have enough %{currency} to drop %{amount}.",
            currency: currency(),
            amount: amount
          )

        state |> Socket.echo(message)
    end
  end

  defp _drop_currency(amount, state = %{save: %{currency: currency}}) do
    save = %{state.save | currency: currency - amount}
    state = Player.update_save(state, save)

    message = gettext("You dropped %{amount} %{currency}.", amount: amount, currency: currency())
    state |> Socket.echo(message)

    @environment.drop_currency(save.room_id, {:player, state.character}, amount)

    {:update, state}
  end

  defp drop_item(item_name, state = %{save: %{items: items}}) do
    items = Items.items(items)

    case Enum.find(items, &Item.matches_lookup?(&1, item_name)) do
      nil ->
        message = gettext(~s(Could not find "%{name}".), name: item_name)
        state |> Socket.echo(message)

      item ->
        _drop_item(item, state)
    end
  end

  defp _drop_item(item, state = %{save: save}) do
    {instance, items} = Item.remove(save.items, item)
    state = Player.update_save(state, %{save | items: items})

    @environment.drop(save.room_id, {:player, state.character}, instance)

    message = gettext("You dropped %{name}.", name: Format.item_name(item))
    state |> Socket.echo(message)

    {:update, state}
  end
end
