defmodule Web.WhoController do
  use Web, :controller

  alias Web.User

  def index(conn, _params) do
    render(conn, :index, players: User.connected_players())
  end
end
