defmodule Web.Admin.ShopController do
  use Web.AdminController

  alias Web.Room
  alias Web.Shop

  def show(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)

    conn
    |> assign(:shop, shop)
    |> assign(:room, room)
    |> render("show.html")
  end

  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)
    changeset = Shop.new(room)

    conn
    |> assign(:room, room)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"room_id" => room_id, "shop" => params}) do
    room = Room.get(room_id)

    case Shop.create(room, params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "#{shop.name} created!")
        |> redirect(to: shop_path(conn, :show, shop.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the shop. Please try again.")
        |> assign(:room, room)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)
    changeset = Shop.edit(shop)

    conn
    |> assign(:shop, shop)
    |> assign(:room, room)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "shop" => params}) do
    case Shop.update(id, params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "#{shop.name} updated!")
        |> redirect(to: shop_path(conn, :show, shop.id))

      {:error, changeset} ->
        shop = Shop.get(id)
        room = Room.get(shop.room_id)

        conn
        |> put_flash(:error, "There was an issue updating #{shop.name}. Please try again.")
        |> assign(:shop, shop)
        |> assign(:room, room)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
