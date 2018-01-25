defmodule Web.PlayController do
  use Web, :controller

  plug(:put_layout, "play.html")

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
