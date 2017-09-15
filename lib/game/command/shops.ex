defmodule Game.Command.Shops do
  @moduledoc """
  The "shops" command
  """

  use Game.Command
  use Game.Currency
  use Game.Shop

  alias Data.Shop
  alias Game.Items

  @custom_parse true
  @commands ["shops"]

  @short_help "View shops and buy from them"
  @full_help """
  Example: shops
  """

  @doc """
  Parse the command into arguments

      iex> Game.Command.Shops.parse("shops")
      {}

      iex> Game.Command.Shops.parse("shops list tree top")
      {:list, "tree top"}

      iex> Game.Command.Shops.parse("shops buy sword from tree top")
      {:buy, "sword", :from, "tree top"}

      iex> Game.Command.Shops.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(command :: String.t) :: {atom}
  def parse(command)
  def parse("shops"), do: {}
  def parse("shops list " <> shop), do: {:list, shop}
  def parse("shops buy " <> string) do
    case Regex.run(~r/(?<item>.+) from (?<shop>.+)/i, string, capture: :all) do
      nil -> {:error, :bad_parse, "shops buy #{string}"}
      [_string, item_name, shop_name] -> {:buy, item_name, :from, shop_name}
    end
  end
  def parse(command), do: {:error, :bad_parse, command}

  @doc """
  #{@short_help}
  """
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    socket |> @socket.echo(Format.shops(room, label: false))
    :ok
  end
  def run({:list, shop_name}, _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    shop = Enum.find(room.shops, fn (shop) -> Shop.matches?(shop, shop_name) end)

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
  def run({:buy, item_name, :from, shop_name}, _session, state = %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    case find_shop(room.shops, shop_name) do
      {:error, :not_found} ->
        socket |> @socket.echo("The \"#{shop_name}\" shop could not be found.")
        :ok
      {:ok, shop} -> buy_item(shop, item_name, state)
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
end
