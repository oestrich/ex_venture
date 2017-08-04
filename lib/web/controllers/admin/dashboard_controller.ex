defmodule Web.Admin.DashboardController do
  use Web, :controller

  plug :put_layout, "admin.html"

  def index(conn, _params) do
    conn |> render("index.html")
  end
end
