defmodule Web.Admin.RoomExitController do
  use Web.AdminController

  alias Web.Room
  alias Web.Zone

  def new(conn, %{"room_id" => room_id, "direction" => direction}) do
    room = Room.get(room_id)
    zone = Zone.get(room.zone_id)
    changeset = Room.new_exit()
    conn |> render("new.html", changeset: changeset, zone: zone, room: room, direction: direction)
  end

  def create(conn, %{"room_id" => room_id, "exit" => params, "direction" => direction}) do
    case Room.create_exit(params) do
      {:ok, _room_exit} ->
        conn |> redirect(to: room_path(conn, :show, room_id))

      {:error, changeset} ->
        room = Room.get(room_id)
        zone = Zone.get(room.zone_id)

        conn
        |> render("new.html", changeset: changeset, zone: zone, room: room, direction: direction)
    end
  end

  def delete(conn, %{"id" => id, "room_id" => room_id}) do
    case Room.delete_exit(id) do
      {:ok, _room_exit} -> conn |> redirect(to: room_path(conn, :show, room_id))
      {:error, _changeset} -> conn |> redirect(to: room_path(conn, :show, room_id))
    end
  end
end
