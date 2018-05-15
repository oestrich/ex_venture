defmodule Web.ChatController do
  use Web, :controller

  plug(Web.Plug.PublicEnsureUser)

  def show(conn, _params) do
    conn |> render("show.html")
  end
end
