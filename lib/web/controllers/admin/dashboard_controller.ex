defmodule Web.Admin.DashboardController do
  use Web.AdminController

  alias Web.User

  def index(conn, _params) do
    conn |> render("index.html", players: User.connected_players())
  end
end
