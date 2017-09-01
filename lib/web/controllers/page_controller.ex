defmodule Web.PageController do
  use Web, :controller

  alias Web.User

  def index(conn, _params) do
    render conn, "index.html"
  end

  def who(conn, _params) do
    render conn, "who.html", players: User.connected_players()
  end
end
