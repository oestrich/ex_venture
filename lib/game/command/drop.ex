defmodule Game.Command.Drop do
  @moduledoc """
  The "drop" command
  """

  use Game.Command
  use Game.Currency

  alias Game.Item
  alias Game.Items

  @must_be_alive true

  commands ["drop"]

  @impl Game.Command
  def help(:topic), do: "Drop"
  def help(:short), do: "Drop an item in the same room"
  def help(:full) do
    """
    Drop an item into the room you are in.

    Example:
    [ ] > {white}drop sword{/white}
    [ ] > {white}drop 10 gold{/white}
    """
  end

  @doc """
  Drop an item in the same room
  """
  @impl Game.Command
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok | {:update, map}
  def run(command, session, state)
  def run({item_name}, _session, state) do
    case Regex.match?(~r{#{@currency}}, item_name) do
      true -> drop_currency(item_name, state)
      false -> drop_item(item_name, state)
    end
  end

  defp drop_currency(amount_to_drop, state = %{socket: socket, save: %{currency: currency}}) do
    amount =
      amount_to_drop
      |> String.split(" ")
      |> List.first
      |> String.to_integer()

    case currency - amount >= 0 do
      true -> _drop_currency(amount, state)
      false ->
        socket |> @socket.echo("You do not have enough #{currency()} to drop #{amount}.")
        :ok
    end
  end

  defp _drop_currency(amount, state = %{socket: socket, save: %{currency: currency}}) do
    save = %{state.save | currency: currency - amount}
    socket |> @socket.echo("You dropped #{amount} #{currency()}")
    @room.drop_currency(save.room_id, {:user, state.user}, amount)
    {:update, Map.put(state, :save, save)}
  end

  defp drop_item(item_name, state = %{socket: socket, save: %{items: items}}) do
    items = Items.items(items)
    case Enum.find(items, &(Item.matches_lookup?(&1, item_name))) do
      nil ->
        socket |> @socket.echo(~s(Could not find "#{item_name}"))
        :ok
      item -> _drop_item(item, state)
    end
  end

  defp _drop_item(item, state = %{socket: socket, user: user, save: save}) do
    {instance, items} = Item.remove(save.items, item)
    save = %{save | items: items}
    socket |> @socket.echo("You dropped #{item.name}")
    @room.drop(save.room_id, {:user, user}, instance)
    {:update, Map.put(state, :save, save)}
  end
end
