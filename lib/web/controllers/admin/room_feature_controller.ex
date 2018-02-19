defmodule Web.Admin.RoomFeatureController do
  use Web.AdminController

  alias Web.Room

  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)
    conn |> render("new.html", room: room, feature: %{})
  end

  def create(conn, %{"room_id" => room_id, "feature" => params}) do
    room = Room.get(room_id)

    case Room.add_feature(room, params) do
      {:ok, _room} ->
        conn |> redirect(to: room_path(conn, :show, room.id))

      {:error, feature} ->
        conn |> render("new.html", room: room, feature: feature)
    end
  end

  def edit(conn, %{"room_id" => room_id, "id" => id}) do
    room = Room.get(room_id)
    feature = Room.get_feature(room, id)
    conn |> render("edit.html", room: room, feature: feature)
  end

  def update(conn, %{"room_id" => room_id, "id" => id, "feature" => params}) do
    room = Room.get(room_id)

    case Room.edit_feature(room, id, params) do
      {:ok, _room} ->
        conn |> redirect(to: room_path(conn, :show, room.id))

      {:error, feature} ->
        conn |> render("edit.html", room: room, feature: feature)
    end
  end

  def delete(conn, %{"room_id" => room_id, "id" => id}) do
    room = Room.get(room_id)

    case Room.delete_feature(room, id) do
      {:ok, _} ->
        conn |> redirect(to: room_path(conn, :show, room.id))

      _ ->
        conn |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
