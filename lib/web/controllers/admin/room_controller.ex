defmodule Web.Admin.RoomController do
  use Web.AdminController

  alias Web.Room
  alias Web.Zone

  def show(conn, %{"id" => id}) do
    room = Room.get(id)
    npcs = Room.npcs(room.id)
    conn |> render("show.html", room: room, npcs: npcs)
  end

  def new(conn, %{"zone_id" => zone_id}) do
    zone = Zone.get(zone_id)
    changeset = Room.new(zone)
    conn |> render("new.html", zone: zone, changeset: changeset)
  end

  def create(conn, %{"zone_id" => zone_id, "room" => params}) do
    zone = Zone.get(zone_id)
    case Room.create(zone, params) do
      {:ok, room} -> conn |> redirect(to: room_path(conn, :show, room.id))
      {:error, changeset} -> conn |> render("new.html", zone: zone, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    room = Room.get(id)
    changeset = Room.edit(room)
    conn |> render("edit.html", room: room, changeset: changeset)
  end

  def update(conn, %{"id" => id, "room" => params}) do
    case Room.update(id, params) do
      {:ok, room} -> conn |> redirect(to: room_path(conn, :show, room.id))
      {:error, changeset} ->
        room = Room.get(id)
        conn |> render("edit.html", room: room, changeset: changeset)
    end
  end
end
