defmodule Web.Admin.RoomExitController do
  use Web.AdminController

  alias Web.Item
  alias Web.Proficiency
  alias Web.Room
  alias Web.Zone

  def new(conn, %{"room_id" => room_id, "direction" => direction}) do
    room = Room.get(room_id)
    zone = Zone.get(room.zone_id)
    changeset = Room.new_exit()

    conn
    |> assign(:changeset, changeset)
    |> assign(:zone, zone)
    |> assign(:room, room)
    |> assign(:direction, direction)
    |> assign(:proficiencies, Proficiency.all())
    |> assign(:items, Item.all())
    |> render("new.html")
  end

  def create(conn, %{"room_id" => room_id, "exit" => params, "direction" => direction}) do
    case Room.create_exit(params) do
      {:ok, _room_exit} ->
        conn
        |> put_flash(:info, "Exit created!")
        |> redirect(to: room_path(conn, :show, room_id))

      {:error, changeset} ->
        room = Room.get(room_id)
        zone = Zone.get(room.zone_id)

        conn
        |> put_flash(:error, "There was an issue creating the exit. Please try again.")
        |> assign(:changeset, changeset)
        |> assign(:zone, zone)
        |> assign(:room, room)
        |> assign(:direction, direction)
        |> assign(:items, Item.all())
        |> render("new.html")
    end
  end

  def delete(conn, %{"id" => id, "room_id" => room_id}) do
    case Room.delete_exit(id) do
      {:ok, _room_exit} ->
        conn
        |> put_flash(:info, "Exit removed!")
        |> redirect(to: room_path(conn, :show, room_id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was an issue removing the exit. Please try again.")
        |> redirect(to: room_path(conn, :show, room_id))
    end
  end
end
