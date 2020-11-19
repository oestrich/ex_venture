defmodule Web.Admin.RoomController do
  use Web, :controller

  alias ExVenture.Rooms

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
end
