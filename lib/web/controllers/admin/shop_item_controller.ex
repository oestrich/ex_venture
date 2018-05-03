defmodule Web.Admin.ShopItemController do
  use Web.AdminController

  alias Web.Item
  alias Web.Room
  alias Web.Shop

  def new(conn, %{"shop_id" => shop_id}) do
    shop = Shop.get(shop_id)
    room = Room.get(shop.room_id)
    changeset = Shop.new_item(shop)

    conn
    |> assign(:items, Item.all())
    |> assign(:shop, shop)
    |> assign(:room, room)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"shop_id" => shop_id, "item" => %{"id" => item_id}, "shop_item" => params}) do
    shop = Shop.get(shop_id)
    item = Item.get(item_id)

    case Shop.add_item(shop, item, params) do
      {:ok, shop_item} ->
        conn
        |> put_flash(:info, "Item added to #{shop.name}!")
        |> redirect(to: shop_path(conn, :show, shop_item.shop_id))

      {:error, changeset} ->
        room = Room.get(shop.room_id)

        conn
        |> put_flash(:error, "There was an issue adding the item to the shop. Please try again.")
        |> assign(:items, Item.all())
        |> assign(:shop, shop)
        |> assign(:room, room)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    shop_item = Shop.get_item(id)
    shop = Shop.get(shop_item.shop_id)
    room = Room.get(shop.room_id)
    changeset = Shop.edit_item(shop_item)

    conn
    |> assign(:items, Item.all())
    |> assign(:shop_item, shop_item)
    |> assign(:shop, shop)
    |> assign(:room, room)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "shop_item" => params}) do
    case Shop.update_item(id, params) do
      {:ok, shop_item} ->
        conn
        |> put_flash(:info, "Item updated!")
        |> redirect(to: shop_path(conn, :show, shop_item.shop_id))

      {:error, changeset} ->
        shop_item = Shop.get_item(id)
        shop = Shop.get(shop_item.shop_id)
        room = Room.get(shop.room_id)

        conn
        |> put_flash(:error, "There was an issue updating the item. Please try again.")
        |> assign(:items, Item.all())
        |> assign(:shop_item, shop_item)
        |> assign(:shop, shop)
        |> assign(:room, room)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Shop.delete_item(id) do
      {:ok, shop_item} ->
        conn
        |> put_flash(:info, "Item deleted!")
        |> redirect(to: shop_path(conn, :show, shop_item.shop_id))

      _ ->
        conn
        |> put_flash(:error, "There was an issue deleting the item from the shop. Please try again.")
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
