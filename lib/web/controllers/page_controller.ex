defmodule Web.PageController do
  use Web, :controller

  alias Web.Announcement
  alias Web.User

  def index(conn, _params) do
    conn
    |> assign(:announcements, Announcement.recent())
    |> render(:index)
  end

  def who(conn, _params) do
    render(conn, "who.html", players: User.connected_players())
  end
end
