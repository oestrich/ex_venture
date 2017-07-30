defmodule Game.Command.Wield do
  @moduledoc """
  The "wield" command
  """

  use Game.Command

  alias Game.Item
  alias Game.Items

  @commands ["wield"]

  @short_help "Put an item in your hands"
  @full_help """
  wield [left|right] item

  Put an item from your inventory into your left or right hand.
  The default hand is your right hand.

  Example: wield right sword
  """

  @doc """
  Put an item in your hands
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run([item_name], _session, state = %{socket: socket, save: %{item_ids: item_ids}}) do
    {hand, item_name} = pick_hand(item_name)

    items = Items.items(item_ids)
    case Item.find_item(items, item_name) do
      nil -> socket |> item_not_found(item_name)
      item -> socket |> item_found(hand, item, state)
    end
  end

  defp item_not_found(socket, item_name) do
    socket |> @socket.echo(~s("#{item_name}" could not be found."))
    :ok
  end

  # Unwield the current item in your hand, adding to inventory
  # Wield the new item, removing from inventory
  defp item_found(socket, hand, item, state) do
    %{save: save} = state
    %{item_ids: item_ids} = save

    {wielding, item_ids} =  unwield(hand, save.wielding, item_ids)
    wielding = Map.put(wielding, hand, item.id)
    save = %{save | item_ids: List.delete(item_ids, item.id), wielding: wielding}

    socket |> @socket.echo(~s(#{item.name} is now in your right hand.))
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
