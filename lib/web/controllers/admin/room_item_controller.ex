defmodule Web.Admin.RoomItemController do
  use Web.AdminController

  alias Web.Item
  alias Web.Room

  def new(conn, %{"room_id" => room_id, "spawn" => "false"}) do
    room = Room.get(room_id)

    conn
    |> assign(:items, Item.all())
    |> assign(:room, room)
    |> render("add-item.html")
  end

  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)
    changeset = Room.new_item(room)

    conn
    |> assign(:items, Item.all())
    |> assign(:room, room)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"room_id" => room_id, "item" => %{"id" => item_id}}) do
    room = Room.get(room_id)

    case Room.add_item(room, item_id) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Item added to #{room.name}")
        |> redirect(to: room_path(conn, :show, room.id))

      {:error, _changeset} ->
        conn
        |> put_flash(
          :error,
          "There was an issue adding the item to #{room.name}. Please try again."
        )
        |> assign(:items, Item.all())
        |> assign(:room, room)
        |> render("add-item.html")
    end
  end

  def create(conn, %{"room_id" => room_id, "room_item" => params}) do
    room = Room.get(room_id)

    case Room.create_item(room, params) do
      {:ok, room_item} ->
        conn
        |> put_flash(:info, "Item spawn added to the room!")
        |> redirect(to: room_path(conn, :show, room_item.room_id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue add the item spawn. Please try again.")
        |> assign(:items, Item.all())
        |> assign(:room, room)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Room.delete_item(id) do
      {:ok, room_item} ->
        conn
        |> put_flash(:info, "Item spawn deleted!")
        |> redirect(to: room_path(conn, :show, room_item.room_id))

      _ ->
        conn
        |> put_flash(:error, "There was an issue deleting the item spawn. Please try again.")
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
