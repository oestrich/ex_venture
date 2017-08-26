defmodule Game.Command.Wield do
  @moduledoc """
  The "wield" command
  """

  use Game.Command

  alias Game.Item
  alias Game.Items

  @custom_parse true
  @commands ["wield", "unwield"]
  @must_be_alive true

  @short_help "Put an item in your hands"
  @full_help """
  wield [left|right] item
  unwield [left|right]

  Put an item from your inventory into your left or right hand.
  The default hand is your right hand.

  Example: wield right sword
  """

  @doc """
  Parse the command to determine wield or unwield

      iex> Game.Command.Wield.parse("wield right sword")
      {:wield, "right sword"}

      iex> Game.Command.Wield.parse("unwield right sword")
      {:unwield, "right sword"}
  """
  @spec parse(command :: String.t) :: []
  def parse("wield " <> command), do: {:wield, command}
  def parse("unwield " <> command), do: {:unwield, command}
  def parse(_), do: {:error, :bad_parse}

  @doc """
  Put an item in your hands
  """
  @spec run(args :: {atom, String.t}, session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({:wield, item_name}, _session, state = %{socket: socket, save: %{item_ids: item_ids}}) do
    {hand, item_name} = pick_hand(item_name)

    items = Items.items(item_ids)
    case Item.find_item(items, item_name) do
      nil -> socket |> item_not_found(item_name)
      item -> socket |> item_found(hand, item, state)
    end
  end
  def run({:unwield, hand}, _session, state = %{socket: socket}) do
    case hand do
      "right" -> run_unwield(:right, state)
      "left" -> run_unwield(:left, state)
      _ ->
        socket |> @socket.echo("Unknown hand")
        :ok
    end
  end

  defp item_not_found(socket, item_name) do
    socket |> @socket.echo(~s("#{item_name}" could not be found."))
    :ok
  end

  # Unwield the current item in your hand, adding to inventory
  # Wield the new item, removing from inventory
  defp item_found(socket, hand, item = %{type: "weapon"}, state) do
    %{save: save} = state
    %{item_ids: item_ids} = save

    {wielding, item_ids} =  unwield(hand, save.wielding, item_ids)
    wielding = Map.put(wielding, hand, item.id)
    save = %{save | item_ids: List.delete(item_ids, item.id), wielding: wielding}

    socket |> @socket.echo(~s(#{item.name} is now in your #{hand} hand.))
    {:update, Map.put(state, :save, save)}
  end
  defp item_found(socket, _, item, _state) do
    socket |> @socket.echo(~s(#{item.name} cannot be wielded))
    :ok
  end

  defp run_unwield(hand, state) do
    %{save: save, socket: socket} = state
    %{item_ids: item_ids} = save

    {wielding, item_ids} =  unwield(hand, save.wielding, item_ids)
    save = %{save | item_ids: item_ids, wielding: wielding}
    socket |> @socket.echo(~s(Your #{hand} hand is now empty.))
    {:update, Map.put(state, :save, save)}
  end

  @doc """
  Determine which hand is being used from the item string

  Examples:

      iex> Game.Command.Wield.pick_hand("sword")
      {:right, "sword"}

      iex> Game.Command.Wield.pick_hand("right sword")
      {:right, "sword"}

      iex> Game.Command.Wield.pick_hand("left sword")
      {:left, "sword"}
  """
  @spec pick_hand(item_string :: String.t) :: {:right, String.t} | {:left, String.t}
  def pick_hand("left " <> item), do: {:left, item}
  def pick_hand("right " <> item), do: {:right, item}
  def pick_hand(item), do: {:right, item}

  @doc """
  Remove an item from your hand and place back into the inventory

  Examples:

      iex> Game.Command.Wield.unwield(:right, %{right: 1}, [])
      {%{}, [1]}
      iex> Game.Command.Wield.unwield(:right, %{right: 1, left: 2}, [3])
      {%{left: 2}, [1, 3]}

      iex> Game.Command.Wield.unwield(:left, %{left: 1}, [])
      {%{}, [1]}
      iex> Game.Command.Wield.unwield(:left, %{right: 1, left: 2}, [3])
      {%{right: 1}, [2, 3]}

      iex> Game.Command.Wield.unwield(:right, %{}, [])
      {%{}, []}
      iex> Game.Command.Wield.unwield(:right, %{left: 1}, [])
      {%{left: 1}, []}

      iex> Game.Command.Wield.unwield(:left, %{}, [])
      {%{}, []}
      iex> Game.Command.Wield.unwield(:left, %{right: 1}, [])
      {%{right: 1}, []}

      iex> Game.Command.Wield.unwield(:right, nil, [])
      {%{}, []}
      iex> Game.Command.Wield.unwield(:left, nil, [])
      {%{}, []}
  """
  @spec unwield(hand :: atom, wielding :: map, item_ids :: [integer]) :: {wielding :: map, inventory :: [integer]}
  def unwield(hand, wielding, item_ids)
  def unwield(:right, wielding = %{right: id}, item_ids) do
    wielding = Map.delete(wielding, :right)
    {wielding, [id | item_ids]}
  end
  def unwield(:left, wielding = %{left: id}, item_ids) do
    wielding = Map.delete(wielding, :left)
    {wielding, [id | item_ids]}
  end
  def unwield(_hand, nil, item_ids), do: {%{}, item_ids}
  def unwield(_hand, wielding, item_ids), do: {wielding, item_ids}
end
