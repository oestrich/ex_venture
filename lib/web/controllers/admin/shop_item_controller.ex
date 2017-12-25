defmodule Web.Admin.ShopItemController do
  use Web.AdminController

  alias Web.Item
  alias Web.Room
  alias Web.Shop

  def new(conn, %{"shop_id" => shop_id}) do
    shop = Shop.get(shop_id)
    room = Room.get(shop.room_id)
    changeset = Shop.new_item(shop)
    conn |> render("new.html", items: Item.all(), shop: shop, room: room, changeset: changeset)
  end

  def create(conn, %{"shop_id" => shop_id, "item" => %{"id" => item_id}, "shop_item" => params}) do
    shop = Shop.get(shop_id)
    item = Item.get(item_id)
    case Shop.add_item(shop, item, params) do
      {:ok, shop_item} -> conn |> redirect(to: shop_path(conn, :show, shop_item.shop_id))
      {:error, changeset} ->
        room = Room.get(shop.room_id)
        conn |> render("new.html", items: Item.all(), shop: shop, room: room, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    shop_item = Shop.get_item(id)
    shop = Shop.get(shop_item.shop_id)
    room = Room.get(shop.room_id)
    changeset = Shop.edit_item(shop_item)
    conn |> render("edit.html", items: Item.all(), shop_item: shop_item, shop: shop, room: room, changeset: changeset)
  end

  def update(conn, %{"id" => id, "shop_item" => params}) do
    case Shop.update_item(id, params) do
      {:ok, shop_item} -> conn |> redirect(to: shop_path(conn, :show, shop_item.shop_id))
      {:error, changeset} ->
        conn |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Shop.delete_item(id) do
      {:ok, shop_item} ->
        conn |> redirect(to: shop_path(conn, :show, shop_item.shop_id))
      _ ->
        conn |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
