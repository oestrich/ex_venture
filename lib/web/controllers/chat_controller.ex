defmodule Web.ChatController do
  use Web, :controller

  plug(Web.Plug.PublicEnsureUser)
  plug(Web.Plug.PublicEnsureCharacter)

  def show(conn, _params) do
    conn |> render("show.html")
  end
end
