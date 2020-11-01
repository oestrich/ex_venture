defmodule Web.Admin.ZoneController do
  use Web, :controller

  alias ExVenture.Zones

  plug(Web.Plugs.ActiveTab, tab: :zones)
  plug(Web.Plugs.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns

    %{page: zones, pagination: pagination} = Zones.all(page: page, per: per)

    conn
    |> assign(:zones, zones)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    case Zones.get(id) do
      {:ok, zone} ->
        conn
        |> assign(:zone, zone)
        |> render("show.html")
    end
  end

  def new(conn, _params) do
    conn
    |> assign(:changeset, Zones.new())
    |> render("new.html")
  end

  def create(conn, %{"zone" => params}) do
    case Zones.create(params) do
      {:ok, zone} ->
        redirect(conn, to: Routes.admin_zone_path(conn, :show, zone.id))

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_status(422)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    case Zones.get(id) do
      {:ok, zone} ->
        conn
        |> assign(:zone, zone)
        |> assign(:changeset, Zones.edit(zone))
        |> render("edit.html")
    end
  end

  def update(conn, %{"id" => id, "zone" => params}) do
    {:ok, zone} = Zones.get(id)

    case Zones.update(zone, params) do
      {:ok, zone} ->
        redirect(conn, to: Routes.admin_zone_path(conn, :show, zone.id))

      {:error, changeset} ->
        conn
        |> assign(:zone, zone)
        |> assign(:changeset, changeset)
        |> put_status(422)
        |> render("edit.html")
    end
  end
end
