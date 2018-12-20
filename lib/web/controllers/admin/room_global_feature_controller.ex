defmodule Web.Admin.RoomGlobalFeatureController do
  use Web.AdminController

  alias Web.Feature
  alias Web.Room

  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    conn
    |> assign(:room, room)
    |> assign(:features, Feature.all())
    |> render("new.html")
  end

  def create(conn, %{"room_id" => room_id, "room" => %{"feature_id" => feature_id}}) do
    room = Room.get(room_id)

    case Room.add_global_feature(room, feature_id) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Room feature added!")
        |> redirect(to: room_path(conn, :show, room.id))

      :error ->
        conn
        |> put_flash(:info, "There was an issue adding the feature. Please try again.")
        |> redirect(to: room_feature_path(conn, :add, room.id))
    end
  end

  def delete(conn, %{"room_id" => room_id, "id" => feature_id}) do
    room = Room.get(room_id)

    case Room.remove_global_feature(room, feature_id) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Room feature removed!")
        |> redirect(to: room_path(conn, :show, room.id))

      :error ->
        conn
        |> put_flash(:info, "There was an issue removing the feature. Please try again.")
        |> redirect(to: room_feature_path(conn, :add, room.id))
    end
  end
end
