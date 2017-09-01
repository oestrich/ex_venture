defmodule Web.Admin.RoomItemController do
  use Web.AdminController

  alias Web.Room

  def delete(conn, %{"id" => id}) do
    case Room.delete_item(id) do
      {:ok, room_item} ->
        conn |> redirect(to: room_path(conn, :show, room_item.room_id))
      _ ->
        conn |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
