defmodule Game.Command.Wear do
  @moduledoc """
  The "wield" command
  """

  use Game.Command

  alias Game.Item
  alias Game.Items

  @custom_parse true
  @commands ["wear", "remove"]
  @must_be_alive true

  @short_help "Put on a piece of armor"
  @full_help """
  wear item
  remove slot

  Example: wear chest
  """

  @doc """
  Parse the command to determine wield or unwield

      iex> Game.Command.Wear.parse("wear chest")
      {:wear, "chest"}

      iex> Game.Command.Wear.parse("remove chest")
      {:remove, "chest"}
  """
  @spec parse(command :: String.t) :: []
  def parse("wear " <> command), do: {:wear, command}
  def parse("remove " <> command), do: {:remove, command}
  def parse(_), do: {:error, :bad_parse}

  @doc """
  Put an item in your hands
  """
  @spec run(args :: {atom, String.t}, session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({:wear, item_name}, _session, state = %{socket: socket, save: %{item_ids: item_ids}}) do
    items = Items.items(item_ids)
    case Item.find_item(items, item_name) do
      nil -> socket |> item_not_found(item_name)
      item -> socket |> item_found(item, state)
    end
  end
  def run({:remove, slot}, _session, state = %{socket: socket}) do
    case slot do
      "chest" -> :chest |> run_remove(state)
      _ ->
        socket |> @socket.echo("Unknown armor slot")
        :ok
    end
  end

  defp item_not_found(socket, item_name) do
    socket |> @socket.echo(~s("#{item_name}" could not be found."))
    :ok
  end

  defp item_found(socket, item = %{type: "armor"}, state) do
    %{save: save} = state
    %{item_ids: item_ids} = save

    {wearing, item_ids} =  remove(item.stats.slot, save.wearing, item_ids)
    wearing = Map.put(wearing, item.stats.slot, item.id)
    save = %{save | item_ids: List.delete(item_ids, item.id), wearing: wearing}

    socket |> @socket.echo(~s(You are now wearing #{item.name}))
    {:update, Map.put(state, :save, save)}
  end
  defp item_found(socket, item, _state) do
    socket |> @socket.echo(~s(You cannot wear #{item.name}))
    :ok
  end

  defp run_remove(slot, state = %{socket: socket, save: save}) do
    %{wearing: wearing, item_ids: item_ids} = save

    case Map.has_key?(wearing, slot) do
      true ->
        item = Items.item(wearing.chest)
        {wearing, item_ids} = remove(:chest, wearing, item_ids)
        save = %{save | wearing: wearing, item_ids: item_ids}

        socket |> @socket.echo("You removed #{item.name} from your chest")
        {:update, Map.put(state, :save, save)}
      false ->
        socket |> @socket.echo("Nothing was on your #{slot}.")
        :ok
    end
  end

  @doc """
  Stop wearing an item

      iex> Game.Command.Wear.remove(:chest, nil, [1])
      {%{}, [1]}

      iex> Game.Command.Wear.remove(:chest, %{chest: 1}, [2])
      {%{}, [1, 2]}
  """
  @spec remove(slot :: :atom, wearing :: map, item_ids :: [integer]) :: {wearing :: map, inventory :: [integer]}
  def remove(slot, wearing, item_ids)
  def remove(_slot, nil, item_ids), do: {%{}, item_ids}
  def remove(slot, wearing, item_ids) do
    case wearing[slot] do
      nil ->
        {Map.delete(wearing, slot), item_ids}
      item_id ->
        {Map.delete(wearing, slot), [item_id | item_ids]}
    end
  end
end
