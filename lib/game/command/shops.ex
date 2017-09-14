defmodule Game.Command.Shops do
  @moduledoc """
  The "shops" command
  """

  use Game.Command
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

      iex> Game.Command.Shops.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(command :: String.t) :: {atom}
  def parse(command)
  def parse("shops"), do: {}
  def parse("shops list " <> shop), do: {:list, shop}
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
end
