defmodule Web.Admin.ZoneController do
  use Web, :controller

  plug :put_layout, "admin.html"

  alias Web.Zone

  def index(conn, _params) do
    zones = Zone.all
    conn |> render("index.html", zones: zones)
  end

  def show(conn, %{"id" => id}) do
    zone = Zone.get(id)
    conn |> render("show.html", zone: zone)
  end
end
