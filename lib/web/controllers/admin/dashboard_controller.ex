defmodule Web.Admin.DashboardController do
  use Web.AdminController

  alias Web.Announcement
  alias Web.User

  def index(conn, _params) do
    conn
    |> assign(:players, User.connected_players())
    |> assign(:announcements, Announcement.recent())
    |> render("index.html")
  end
end
