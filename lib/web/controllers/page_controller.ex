defmodule Web.PageController do
  use Web, :controller

  alias Web.Announcement
  alias Web.Zone

  def index(conn, _params) do
    conn
    |> assign(:announcements, Announcement.recent())
    |> render(:index)
  end

  def version(conn, _params) do
    text(conn, "#{ExVenture.version()} - #{ExVenture.sha_version()}")
  end

  def mudlet_package(conn, _params) do
    render(conn, "mudlet-package.xml")
  end

  def map(conn, _params) do
    conn
    |> assign(:zones, Zone.all())
    |> render("map.xml")
  end

  def manifest(conn, _params) do
    conn
    |> put_resp_header("content-type", "application/manifest+json")
    |> render("manifest.json")
  end
end
