defmodule Web.API.StagedChangeController do
  use Web, :controller

  alias ExVenture.Rooms
  alias ExVenture.StagedChanges
  alias ExVenture.Zones

  def index(conn, %{"room_id" => room_id}) do
    {:ok, room} = Rooms.get(room_id)

    conn
    |> assign(:staged_changes, room.staged_changes)
    |> render("index.json")
  end

  def index(conn, %{"zone_id" => zone_id}) do
    {:ok, zone} = Zones.get(zone_id)

    conn
    |> assign(:staged_changes, zone.staged_changes)
    |> render("index.json")
  end

  def index(conn, %{"type" => "rooms"}) do
    conn
    |> assign(:staged_changes, StagedChanges.changes(Rooms.Room))
    |> render("index.json")
  end

  def index(conn, %{"type" => "zones"}) do
    conn
    |> assign(:staged_changes, StagedChanges.changes(Zones.Zone))
    |> render("index.json")
  end

  def index(conn, _params) do
    conn
    |> put_status(404)
    |> put_view(Web.ErrorView)
    |> render("404.json")
  end
end
