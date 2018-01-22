defmodule Game.Command.Shops do
  @moduledoc """
  The "shops" command
  """

  use Game.Command
  use Game.Currency
  use Game.Shop

  alias Data.Shop
  alias Game.Items

  commands ["shops", "shop", "buy", "sell"], parse: false

  @impl Game.Command
  def help(:topic), do: "Shops"
  def help(:short), do: "View shops and buy from them"
  def help(:full) do
    """
    View shops:
    [ ] > {white}shops{/white}

    List items in a shop:
    [ ] > {white}shops list shop name{/white}
    [ ] > {white}shop list{/white}

    View an item in a shop:
    [ ] > {white}shops show item from shop name{/white}
    [ ] > {white}shop show item{/white}

    Buy an item from a shop:
    [ ] > {white}buy item from shop name{/white}
    [ ] > {white}buy item{/white}

    Sell an item to a shop:
    [ ] > {white}sell item to shop name{/white}
    [ ] > {white}sell item{/white}

    When matching a shop name, you can use the shortest unique string for
    the shop. So "{magenta}Blacksmith{/magenta}" can be matched with "{white}blac{/white}".
    """
  end

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
  @spec parse(command :: String.t) :: {atom}
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
  @spec _parse_shop_command(base_command :: atom, string :: String.t, from_or_to :: atom) :: :ok
  def _parse_shop_command(base_command, string, from_or_to) do
    case Regex.run(~r/(?<item>.+) #{from_or_to} (?<shop>.+)/i, string, capture: :all) do
      nil -> {base_command, string}
      [_string, item_name, shop_name] -> {base_command, item_name, from_or_to, shop_name}
    end
  end

  @doc """
  View shops and buy from them
  """
  @impl Game.Command
  @spec run(args :: [], state :: map) :: :ok
  def run(command, state)
  def run({}, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case length(room.shops) do
      0 ->
        socket |> @socket.echo("There are no shops here.")
      _ ->
        socket |> @socket.echo(Format.shops(room, label: false))
    end
    :ok
  end

  def run({:help}, %{socket: socket}) do
    socket |> @socket.echo("Unknown usage of the shop(s) command. Please see {white}help shops{/white} for more information.")
    :ok
  end

  def run({:list, shop_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case find_shop(room.shops, shop_name) do
      {:error, :not_found} ->
        socket |> @socket.echo("The \"#{shop_name}\" shop could not be found.")
        :ok
      {:ok, shop} -> list_items(shop, state)
    end
  end

  def run({:list}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case one_shop(room.shops) do
      {:error, :not_found} ->
        socket |> @socket.echo("The shop could not be found.")
        :ok
      {:error, :more_than_one_shop} ->
        more_than_one_shop(socket)
        :ok
      {:ok, shop} -> list_items(shop, state)
    end
  end

  def run({:show, item_name, :from, shop_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case find_shop(room.shops, shop_name) do
      {:error, :not_found} ->
        socket |> @socket.echo("The \"#{shop_name}\" shop could not be found.")
        :ok
      {:ok, shop} -> show_item(shop, item_name, state)
    end
  end
  def run({:show, item_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case one_shop(room.shops) do
      {:error, :not_found} ->
        socket |> @socket.echo("The shop could not be found.")
        :ok
      {:error, :more_than_one_shop} ->
        more_than_one_shop(socket)
        :ok
      {:ok, shop} -> show_item(shop, item_name, state)
    end
  end

  def run({:buy, item_name, :from, shop_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case find_shop(room.shops, shop_name) do
      {:error, :not_found} ->
        socket |> @socket.echo("The \"#{shop_name}\" shop could not be found.")
        :ok
      {:ok, shop} -> buy_item(shop, item_name, state)
    end
  end
  def run({:buy, item_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case one_shop(room.shops) do
      {:error, :not_found} ->
        socket |> @socket.echo("The shop could not be found.")
        :ok
      {:error, :more_than_one_shop} ->
        more_than_one_shop(socket)
        :ok
      {:ok, shop} -> buy_item(shop, item_name, state)
    end
  end

  def run({:sell, item_name, :to, shop_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case find_shop(room.shops, shop_name) do
      {:error, :not_found} ->
        socket |> @socket.echo("The \"#{shop_name}\" shop could not be found.")
        :ok
      {:ok, shop} -> sell_item(shop, item_name, state)
    end
  end
  def run({:sell, item_name}, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case one_shop(room.shops) do
      {:error, :not_found} ->
        socket |> @socket.echo("The shop could not be found.")
        :ok
      {:error, :more_than_one_shop} ->
        more_than_one_shop(socket)
        :ok
      {:ok, shop} -> sell_item(shop, item_name, state)
    end
  end

  defp find_shop(shops, shop_name) do
    case shop = Enum.find(shops, fn (shop) -> Shop.matches?(shop, shop_name) end) do
      nil -> {:error, :not_found}
      shop ->
        shop = @shop.list(shop.id)
        {:ok, shop}
    end
  end

  defp list_items(shop, %{socket: socket}) do
    shop = @shop.list(shop.id)
    items = Enum.map(shop.shop_items, fn (shop_item) ->
      shop_item.item_id
      |> Items.item()
      |> Map.put(:price, shop_item.price)
      |> Map.put(:quantity, shop_item.quantity)
    end)

    socket |> @socket.echo(Format.list_shop(shop, items))
    :ok
  end

  defp one_shop(shops) do
    case shops do
      [shop] ->
        {:ok, @shop.list(shop.id)}
      [_ | _tail] -> {:error, :more_than_one_shop}
      _ -> {:error, :not_found}
    end
  end

  defp buy_item(shop, item_name, state = %{socket: socket, save: save}) do
    case shop.id |> @shop.buy(item_name, save) do
      {:ok, save, item} ->
        socket |> @socket.echo("You bought #{item.name} from #{shop.name}.")
        state = %{state | save: save}
        {:update, state}
      {:error, :item_not_found} ->
        socket |> @socket.echo("The \"#{item_name}\" item could not be found.")
        :ok
      {:error, :not_enough_currency, item} ->
        socket |> @socket.echo("You do not have enought #{currency()} for #{item.name}.")
        :ok
      {:error, :not_enough_quantity, item} ->
        socket |> @socket.echo("\"#{shop.name}\" does not have enough of #{item.name} for you to buy.")
        :ok
    end
  end

  defp sell_item(shop, item_name, state = %{socket: socket, save: save}) do
    case shop.id |> @shop.sell(item_name, save) do
      {:ok, save, item} ->
        socket |> @socket.echo("You sold #{item.name} to #{shop.name} for #{item.cost} #{currency()}.")
        state = %{state | save: save}
        {:update, state}
      {:error, :item_not_found} ->
        socket |> @socket.echo("The \"#{item_name}\" item could not be found.")
        :ok
    end
  end

  defp show_item(shop, item_name, %{socket: socket}) do
    items = Enum.map(shop.shop_items, &(Items.item(&1.item_id)))
    case Enum.find(items, &(Game.Item.matches_lookup?(&1, item_name))) do
      nil -> socket |> @socket.echo("The \"#{item_name}\" could not be found in #{shop.name}.")
      item -> socket |> @socket.echo(Format.item(item))
    end
  end

  defp more_than_one_shop(socket) do
    socket |> @socket.echo("""
    There is more than one shop in the room, please add the shop you want to use to the command.
    See {white}help shops{/white} for more information.
    """)
  end
end
