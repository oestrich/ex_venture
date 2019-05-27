defmodule Game.Command.Shops do
  @moduledoc """
  The "shops" command
  """

  use Game.Command
  use Game.Currency
  use Game.Shop

  alias Game.Environment
  alias Game.Environment.State.Overworld
  alias Game.Format.Items, as: FormatItems
  alias Game.Format.Rooms, as: FormatRooms
  alias Game.Format.Shops, as: FormatShops
  alias Game.Items
  alias Game.Utility

  commands(["shops", "shop", "buy", "sell"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Shops"
  def help(:short), do: "View shops and buy from them"

  def help(:full) do
    """
    Some rooms have shops in them. You will see them on their own line
    in the room's description. In general, if there is only one shop in
    a room, you can omit the shop name at the end of the command.

    View shops in the room:
    [ ] > {command}shops{/command}

    List items in a shop:
    [ ] > {command}shops list shop name{/command}
    [ ] > {command}shop list{/command}

    View an item in a shop:
    [ ] > {command}shops show item from shop name{/command}
    [ ] > {command}shop show item{/command}

    Buy an item from a shop:
    [ ] > {command}buy item from shop name{/command}
    [ ] > {command}buy item{/command}

    Sell an item to a shop:
    [ ] > {command}sell item to shop name{/command}
    [ ] > {command}sell item{/command}

    When matching a shop name, you can use the shortest unique string for
    the shop. So "{shop}Blacksmith{/shop}" can be matched with "{command}blac{/command}".
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Shops.parse("shops")
      {}

      iex> Game.Command.Shops.parse("shops list tree top")
      {:list, "tree top"}
      iex> Game.Command.Shops.parse("shop list")
      {:list}

      iex> Game.Command.Shops.parse("shops buy sword from tree top")
      {:buy, "sword", :from, "tree top"}
      iex> Game.Command.Shops.parse("buy sword from tree top")
      {:buy, "sword", :from, "tree top"}
      iex> Game.Command.Shops.parse("buy sword")
      {:buy, "sword"}

      iex> Game.Command.Shops.parse("shops sell sword to tree top")
      {:sell, "sword", :to, "tree top"}
      iex> Game.Command.Shops.parse("sell sword to tree top")
      {:sell, "sword", :to, "tree top"}
      iex> Game.Command.Shops.parse("sell sword")
      {:sell, "sword"}

      iex> Game.Command.Shops.parse("shops show sword from tree top")
      {:show, "sword", :from, "tree top"}
      iex> Game.Command.Shops.parse("shop show sword")
      {:show, "sword"}

      iex> Game.Command.Shops.parse("shops bad")
      {:help}
      iex> Game.Command.Shops.parse("shop bad")
      {:help}

      iex> Game.Command.Shops.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("shops"), do: {}
  def parse("shops list " <> shop), do: {:list, shop}
  def parse("shop list"), do: {:list}
  def parse("shops buy " <> string), do: _parse_shop_command(:buy, string, :from)
  def parse("buy " <> string), do: _parse_shop_command(:buy, string, :from)
  def parse("shops sell " <> string), do: _parse_shop_command(:sell, string, :to)
  def parse("sell " <> string), do: _parse_shop_command(:sell, string, :to)
  def parse("shops show " <> string), do: _parse_shop_command(:show, string, :from)
  def parse("shop show " <> string), do: {:show, string}
  def parse("shop" <> _string), do: {:help}

  @doc """
  Handle the common parsing code for an item name and then the shop
  """
  @spec _parse_shop_command(atom, String.t(), atom) :: :ok
  def _parse_shop_command(base_command, string, from_or_to) do
    case Regex.run(~r/(?<item>.+) #{from_or_to} (?<shop>.+)/i, string, capture: :all) do
      nil -> {base_command, string}
      [_string, item_name, shop_name] -> {base_command, item_name, from_or_to, shop_name}
    end
  end

  @impl Game.Command
  @doc """
  View shops and buy from them
  """
  def run(command, state)

  def run({}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case Environment.room_type(room_id) do
      :room ->
        case Enum.empty?(room.shops) do
          true ->
            state |> Socket.echo("There are no shops here.")

          false ->
            state |> Socket.echo(FormatRooms.list_shops(room))
        end

      :overworld ->
        state |> Socket.echo("There are no shops here.")
    end
  end

  def run({:help}, state) do
    message = "Unknown usage of the shop(s) command. Please see {command}help shops{/command} for more information."
    state |> Socket.echo(message)
  end

  def run({:list, shop_name}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case find_shop(room, shop_name) do
      {:error, :not_found} ->
        message = "The \"#{shop_name}\" shop could not be found."
        state |> Socket.echo(message)

      {:ok, shop} ->
        list_items(shop, state)
    end
  end

  def run({:list}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case one_shop(room) do
      {:error, :not_found} ->
        state |> Socket.echo("The shop could not be found.")

      {:error, :more_than_one_shop} ->
        more_than_one_shop(state)

      {:ok, shop} ->
        list_items(shop, state)
    end
  end

  def run({:show, item_name, :from, shop_name}, state) do
    %{save: %{room_id: room_id}} = state

    {:ok, room} = Environment.look(room_id)

    case find_shop(room, shop_name) do
      {:error, :not_found} ->
        message = "The \"#{shop_name}\" shop could not be found."
        state |> Socket.echo(message)

      {:ok, shop} ->
        show_item(shop, item_name, state)
    end
  end

  def run({:show, item_name}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case one_shop(room) do
      {:error, :not_found} ->
        state |> Socket.echo("The shop could not be found.")

      {:error, :more_than_one_shop} ->
        more_than_one_shop(state)

      {:ok, shop} ->
        show_item(shop, item_name, state)
    end
  end

  def run({:buy, item_name, :from, shop_name}, state) do
    %{save: %{room_id: room_id}} = state

    {:ok, room} = Environment.look(room_id)

    case find_shop(room, shop_name) do
      {:error, :not_found} ->
        message = "The \"#{shop_name}\" shop could not be found."
        state |> Socket.echo(message)

      {:ok, shop} ->
        buy_item(shop, item_name, state)
    end
  end

  def run({:buy, item_name}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case one_shop(room) do
      {:error, :not_found} ->
        state |> Socket.echo("The shop could not be found.")

      {:error, :more_than_one_shop} ->
        more_than_one_shop(state)

      {:ok, shop} ->
        buy_item(shop, item_name, state)
    end
  end

  def run({:sell, item_name, :to, shop_name}, state) do
    %{save: %{room_id: room_id}} = state

    {:ok, room} = Environment.look(room_id)

    case find_shop(room, shop_name) do
      {:error, :not_found} ->
        message = "The \"#{shop_name}\" shop could not be found."
        state |> Socket.echo(message)

      {:ok, shop} ->
        sell_item(shop, item_name, state)
    end
  end

  def run({:sell, item_name}, state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    case one_shop(room) do
      {:error, :not_found} ->
        state |> Socket.echo("The shop could not be found.")

      {:error, :more_than_one_shop} ->
        more_than_one_shop(state)

      {:ok, shop} ->
        sell_item(shop, item_name, state)
    end
  end

  defp find_shop(_room = %Overworld{}, _shop_name), do: {:error, :not_found}

  defp find_shop(room, shop_name) do
    case Enum.find(room.shops, fn shop -> Utility.matches?(shop, shop_name) end) do
      nil ->
        {:error, :not_found}

      shop ->
        shop = @shop.list(shop.id)
        {:ok, shop}
    end
  end

  defp list_items(shop, state) do
    shop = @shop.list(shop.id)

    items =
      Enum.map(shop.shop_items, fn shop_item ->
        shop_item.item_id
        |> Items.item()
        |> Map.put(:price, shop_item.price)
        |> Map.put(:quantity, shop_item.quantity)
      end)

    state |> Socket.echo(FormatShops.list(shop, items))
  end

  defp one_shop(_room = %Overworld{}), do: {:error, :not_found}

  defp one_shop(room) do
    case room.shops do
      [shop] ->
        {:ok, @shop.list(shop.id)}

      [_ | _tail] ->
        {:error, :more_than_one_shop}

      _ ->
        {:error, :not_found}
    end
  end

  defp buy_item(shop, item_name, state = %{save: save}) do
    case shop.id |> @shop.buy(item_name, save) do
      {:ok, save, item} ->
        item = FormatItems.item_name(item)
        shop = FormatShops.shop_name(shop)
        message = "You bought #{item} from #{shop}."
        state |> Socket.echo(message)

        state = %{state | save: save}
        {:update, state}

      {:error, :item_not_found} ->
        message = "The \"#{item_name}\" item could not be found."
        state |> Socket.echo(message)

      {:error, :not_enough_currency, item} ->
        item = FormatItems.item_name(item)
        message = "You do not have enough #{currency()} for #{item}."
        state |> Socket.echo(message)

      {:error, :not_enough_quantity, item} ->
        shop = FormatShops.shop_name(shop)
        item = FormatItems.item_name(item)
        message = "#{shop} does not have enough of #{item} for you to buy."
        state |> Socket.echo(message)
    end
  end

  defp sell_item(shop, item_name, state = %{save: save}) do
    case shop.id |> @shop.sell(item_name, save) do
      {:ok, save, item} ->
        item_name = FormatItems.item_name(item)
        shop = FormatShops.shop_name(shop)
        message = "You sold #{item_name} to #{shop} for #{item.cost} #{currency()}."
        state |> Socket.echo(message)

        state = %{state | save: save}
        {:update, state}

      {:error, :item_not_found} ->
        message = "The \"#{item_name}\" item could not be found."
        state |> Socket.echo(message)
    end
  end

  defp show_item(shop, item_name, state) do
    items = Enum.map(shop.shop_items, &Items.item(&1.item_id))

    case Enum.find(items, &Game.Item.matches_lookup?(&1, item_name)) do
      nil ->
        shop = FormatShops.shop_name(shop)
        message = "The \"#{item_name}\" could not be found in #{shop}."
        state |> Socket.echo(message)

      item ->
        state |> Socket.echo(FormatItems.item(item))
    end
  end

  defp more_than_one_shop(state) do
    message = """
    There is more than one shop in the room, please add the shop you want to use to the command.
    See {command}help shops{/command} for more information.
    """

    state |> Socket.echo(message)
  end
end
