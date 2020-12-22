defmodule Web.API.ZoneController do
  use Web, :controller

  alias ExVenture.Zones

  plug(Web.Plugs.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns

    %{page: zones, pagination: pagination} = Zones.all(page: page, per: per)

    conn
    |> assign(:zones, zones)
    |> assign(:pagination, pagination)
    |> render("index.json")
  end

  def show(conn, %{"id" => id}) do
    case Zones.get(id) do
      {:ok, zone} ->
        conn
        |> assign(:zone, zone)
        |> assign(:mini_map, Zones.make_mini_map(zone))
        |> render("show.json")
    end
  end
end
