defmodule Web.PlayController do
  use Web, :controller

  plug(Web.Plug.PublicEnsureUser)
  plug(Web.Plug.PublicEnsureCharacter)
  plug(:put_layout, "play.html")

  def show(conn, _params) do
    render(conn, "show.html")
  end

  def show_react(conn, _params) do
    conn = put_layout conn, "play_react.html"
    render(conn, "show_react.html")
  end
end
