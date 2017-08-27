defmodule Web.Admin.ZoneController do
  use Web.AdminController

  alias Web.Zone

  def index(conn, _params) do
    zones = Zone.all
    conn |> render("index.html", zones: zones)
  end

  def show(conn, %{"id" => id}) do
    zone = Zone.get(id)
    conn |> render("show.html", zone: zone)
  end

  def new(conn, _params) do
    changeset = Zone.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"zone" => params}) do
    case Zone.create(params) do
      {:ok, zone} -> conn |> redirect(to: zone_path(conn, :show, zone.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    zone = Zone.get(id)
    changeset = Zone.edit(zone)
    conn |> render("edit.html", zone: zone, changeset: changeset)
  end

  def update(conn, %{"id" => id, "zone" => params}) do
    case Zone.update(id, params) do
      {:ok, zone} -> conn |> redirect(to: zone_path(conn, :show, zone.id))
      {:error, changeset} ->
        zone = Zone.get(id)
        conn |> render("edit.html", zone: zone, changeset: changeset)
    end
  end
end
