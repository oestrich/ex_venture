defmodule Web.Admin.InsightController do
  use Web.AdminController

  def index(conn, _params) do
    conn |> render("index.html")
  end
end
