defmodule Game.Command.Wear do
  @moduledoc """
  The "wield" command
  """

  use Game.Command

  alias Data.Stats
  alias Game.Format
  alias Game.Item
  alias Game.Items

  @must_be_alive true

  commands(["wear", "remove"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Wear"
  def help(:short), do: "Put on a piece of armor"

  def help(:full) do
    """
    Put on a peice of armor, or remove it from a slot. {command}Wear{/command} takes the item
    name, and {command}remove{/command} takes the slot or item name. You must be of the same
    or greater level than the item to wear it.

    Example:
    [ ] > {command}wear chest piece{/command}
    [ ] > {command}remove chest{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command to determine wield or unwield

      iex> Game.Command.Wear.parse("wear chest")
      {:wear, "chest"}

      iex> Game.Command.Wear.parse("remove chest")
      {:remove, "chest"}

      iex> Game.Command.Wear.parse("remve chest")
      {:error, :bad_parse, "remve chest"}
  """
  @spec parse(String.t()) :: []
  def parse("wear " <> command), do: {:wear, command}
  def parse("remove " <> command), do: {:remove, command}

  @impl Game.Command
  @doc """
  Put an item in your hands
  """
  def run(command, state)

  def run({:wear, item_name}, state) do
    items = Items.items(state.save.items)

    with {:ok, item} <- Item.find_item(items, item_name),
         {:ok, item} <- Item.check_item_level(item, state.save),
         {:ok, item} <- Item.check_can_wear(item) do
      state |> item_found(item)
    else
      {:error, :level_too_low, item} ->
        message = "You cannot wear \"#{Format.item_name(item)}\", you are not high enough level."
        state.socket |> @socket.echo(message)

      {:error, :cannot_wear, item} ->
        state.socket |> @socket.echo(~s(You cannot wear #{item.name}.))

      {:error, :not_found} ->
        state.socket |> @socket.echo(~s("#{item_name}" could not be found."))
    end
  end

  def run({:remove, slot}, state = %{socket: socket}) do
    slots = Enum.map(Stats.slots(), &to_string/1)

    case slot in slots do
      true ->
        slot |> String.to_atom() |> run_remove(state)

      false ->
        socket |> @socket.echo("Unknown armor slot")
        :ok
    end
  end

  defp item_found(state, item) do
    %{save: save} = state
    %{items: items} = save

    {wearing, items} = remove(item.stats.slot, save.wearing, items)
    {instance, items} = Item.remove(items, item)
    wearing = Map.put(wearing, item.stats.slot, instance)

    save = %{save | items: items, wearing: wearing}

    state.socket |> @socket.echo(~s(You are now wearing #{item.name}))

    {:update, Map.put(state, :save, save)}
  end

  defp run_remove(slot, state = %{socket: socket, save: save}) do
    %{wearing: wearing, items: items} = save

    case Map.has_key?(wearing, slot) do
      true ->
        item = Items.item(wearing[slot])
        {wearing, items} = remove(slot, wearing, items)
        save = %{save | wearing: wearing, items: items}

        socket |> @socket.echo("You removed #{item.name} from your #{slot}")
        {:update, Map.put(state, :save, save)}

      false ->
        socket |> @socket.echo("Nothing was on your #{slot}.")
        :ok
    end
  end

  @doc """
  Stop wearing an item
  """
  @spec remove(:atom, map, [integer]) :: {map, [integer]}
  def remove(slot, wearing, items)
  def remove(_slot, nil, items), do: {%{}, nil, items}

  def remove(slot, wearing, items) do
    case wearing[slot] do
      nil ->
        {Map.delete(wearing, slot), items}

      item ->
        {Map.delete(wearing, slot), [item | items]}
    end
  end
end
