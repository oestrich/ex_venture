defmodule Web.Admin.ZoneController do
  use Web.AdminController

  alias Web.Zone

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: zones, pagination: pagination} = Zone.all(page: page, per: per)

    conn
    |> assign(:zones, zones)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    zone = Zone.get(id)

    conn
    |> assign(:zone, zone)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Zone.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"zone" => params}) do
    case Zone.create(params) do
      {:ok, zone} ->
        conn
        |> put_flash(:info, "#{zone.name} created!")
        |> redirect(to: zone_path(conn, :show, zone.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the zone. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    zone = Zone.get(id)
    changeset = Zone.edit(zone)

    conn
    |> assign(:zone, zone)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "zone" => params}) do
    case Zone.update(id, params) do
      {:ok, zone} ->
        conn
        |> put_flash(:info, "#{zone.name} updated!")
        |> redirect(to: zone_path(conn, :show, zone.id))

      {:error, changeset} ->
        zone = Zone.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{zone.name}. Please try again.")
        |> assign(:zone, zone)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
