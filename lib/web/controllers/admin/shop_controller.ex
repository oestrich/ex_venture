defmodule Web.Admin.ShopController do
  use Web.AdminController

  alias Web.Room
  alias Web.Shop

  def show(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)
    conn |> render("show.html", shop: shop, room: room)
  end

  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)
    changeset = Shop.new(room)
    conn |> render("new.html", room: room, changeset: changeset)
  end

  def create(conn, %{"room_id" => room_id, "shop" => params}) do
    room = Room.get(room_id)
    case Shop.create(room, params) do
      {:ok, shop} -> conn |> redirect(to: shop_path(conn, :show, shop.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)
    changeset = Shop.edit(shop)
    conn |> render("edit.html", shop: shop, room: room, changeset: changeset)
  end

  def update(conn, %{"id" => id, "shop" => params}) do
    case Shop.update(id, params) do
      {:ok, shop} -> conn |> redirect(to: shop_path(conn, :show, shop.id))
      {:error, changeset} ->
        shop = Shop.get(id)
        room = Room.get(shop.room_id)
        conn |> render("edit.html", room: room, changeset: changeset)
    end
  end
end
