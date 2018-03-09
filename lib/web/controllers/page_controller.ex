defmodule Web.PageController do
  use Web, :controller

  alias Web.Announcement
  alias Web.User

  def index(conn, _params) do
    render(conn, "index.html", announcements: Announcement.recent())
  end

  def who(conn, _params) do
    render(conn, "who.html", players: User.connected_players())
  end
end
