defmodule Web.PageController do
  use Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def client(conn, _params) do
    conn
    |> put_layout("simple.html")
    |> render("client.html")
  end
end
