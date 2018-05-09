defmodule Web.Admin.RoomController do
  use Web.AdminController

  alias Web.Room
  alias Web.Zone

  def show(conn, %{"id" => id}) do
    room = Room.get(id)

    conn
    |> assign(:room, room)
    |> render("show.html")
  end

  def new(conn, params = %{"zone_id" => zone_id}) do
    zone = Zone.get(zone_id)
    changeset = Room.new(zone, params)

    conn
    |> assign(:zone, zone)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"zone_id" => zone_id, "room" => params}) do
    zone = Zone.get(zone_id)

    case Room.create(zone, params) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "#{room.name} created!")
        |> redirect(to: room_path(conn, :show, room.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the room. Please try again.")
        |> assign(:zone, zone)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    room = Room.get(id)
    changeset = Room.edit(room)

    conn
    |> assign(:room, room)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "room" => params}) do
    case Room.update(id, params) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "#{room.name} updated!")
        |> redirect(to: room_path(conn, :show, room.id))

      {:error, changeset} ->
        room = Room.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{room.name}. Please try again.")
        |> assign(:room, room)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Room.delete(id) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "#{room.name} has been deleted!")
        |> redirect(to: zone_path(conn, :show, room.zone_id))

      {:error, :graveyard, room} ->
        conn
        |> put_flash(:error, "#{room.name} is a graveyard, could not be deleted")
        |> redirect(to: room_path(conn, :show, room.id))
    end
  end
end
