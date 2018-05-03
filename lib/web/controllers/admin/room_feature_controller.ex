defmodule Web.Admin.RoomFeatureController do
  use Web.AdminController

  alias Web.Room

  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    conn
    |> assign(:room, room)
    |> assign(:feature, %{})
    |> render("new.html")
  end

  def create(conn, %{"room_id" => room_id, "feature" => params}) do
    room = Room.get(room_id)

    case Room.add_feature(room, params) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Feature added!")
        |> redirect(to: room_path(conn, :show, room.id))

      {:error, feature} ->
        conn
        |> put_flash(:error, "There was an issue adding the feature. Please try again.")
        |> assign(:room, room)
        |> assign(:feature, feature)
        |> render("new.html")
    end
  end

  def edit(conn, %{"room_id" => room_id, "id" => id}) do
    room = Room.get(room_id)
    feature = Room.get_feature(room, id)

    conn
    |> assign(:room, room)
    |> assign(:feature, feature)
    |> render("edit.html")
  end

  def update(conn, %{"room_id" => room_id, "id" => id, "feature" => params}) do
    room = Room.get(room_id)

    case Room.edit_feature(room, id, params) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Room feature updated!")
        |> redirect(to: room_path(conn, :show, room.id))

      {:error, feature} ->
        conn
        |> put_flash(:info, "There was an issue updating the feature. Please try again.")
        |> assign(:room, room)
        |> assign(:feature, feature)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"room_id" => room_id, "id" => id}) do
    room = Room.get(room_id)

    case Room.delete_feature(room, id) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Feature removed!")
        |> redirect(to: room_path(conn, :show, room.id))

      _ ->
        conn
        |> put_flash(:error, "There was an issue removing the feature. Please try again.")
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
