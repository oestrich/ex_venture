defmodule Web.Admin.RoomController do
  use Web, :controller

  alias ExVenture.Rooms
  alias ExVenture.StagedChanges
  alias ExVenture.Zones

  plug(Web.Plugs.ActiveTab, tab: :rooms)
  plug(Web.Plugs.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns

    %{page: rooms, pagination: pagination} = Rooms.all(page: page, per: per)

    conn
    |> assign(:rooms, rooms)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    case Rooms.get(id) do
      {:ok, room} ->
        conn
        |> assign(:room, room)
        |> assign(:zone, room.zone)
        |> render("show.html")
    end
  end

  def new(conn, %{"zone_id" => zone_id}) do
    {:ok, zone} = Zones.get(zone_id)

    conn
    |> assign(:changeset, Rooms.new(zone))
    |> assign(:zone, zone)
    |> render("new.html")
  end

  def create(conn, %{"zone_id" => zone_id, "room" => params}) do
    {:ok, zone} = Zones.get(zone_id)

    case Rooms.create(zone, params) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Room created!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:zone, zone)
        |> put_status(422)
        |> put_flash(:error, "Could not save the room")
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    case Rooms.get(id) do
      {:ok, room} ->
        conn
        |> assign(:changeset, Rooms.edit(room))
        |> assign(:room, room)
        |> assign(:zone, room.zone)
        |> render("edit.html")
    end
  end

  def update(conn, %{"id" => id, "room" => params}) do
    {:ok, room} = Rooms.get(id)

    case Rooms.update(room, params) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Room created!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      {:error, changeset} ->
        conn
        |> assign(:room, room)
        |> assign(:changeset, changeset)
        |> assign(:zone, room.zone)
        |> put_status(422)
        |> put_flash(:error, "Could not save the room")
        |> render("edit.html")
    end
  end

  def publish(conn, %{"id" => id}) do
    {:ok, room} = Rooms.get(id)

    case Rooms.publish(room) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Room Published!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))
    end
  end

  def delete_changes(conn, %{"id" => id}) do
    {:ok, room} = Rooms.get(id)

    case StagedChanges.clear(room) do
      {:ok, room} ->
        redirect(conn, to: Routes.admin_room_path(conn, :show, room.id))
    end
  end
end
