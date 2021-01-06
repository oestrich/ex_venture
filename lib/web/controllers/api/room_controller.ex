defmodule Web.API.RoomController do
  use Web, :controller

  alias ExVenture.Rooms
  alias ExVenture.Zones

  plug(Web.Plugs.FetchPage when action in [:index])

  def index(conn, %{"zone_id" => zone_id}) do
    %{page: page, per: per} = conn.assigns

    with {:ok, zone} <- Zones.get(zone_id) do
      %{page: rooms, pagination: pagination} = Rooms.all(zone, page: page, per: per)

      conn
      |> assign(:rooms, rooms)
      |> assign(:zone, zone)
      |> assign(:pagination, pagination)
      |> render("index.json")
    end
  end

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns

    %{page: rooms, pagination: pagination} = Rooms.all(page: page, per: per)

    conn
    |> assign(:rooms, rooms)
    |> assign(:pagination, pagination)
    |> render("index.json")
  end

  def show(conn, %{"id" => id}) do
    case Rooms.get(id) do
      {:ok, room} ->
        conn
        |> assign(:room, room)
        |> render("show.json")

      {:error, :not_found} ->
        conn
        |> put_status(404)
        |> put_view(Web.ErrorView)
        |> render("404.json")
    end
  end
end
