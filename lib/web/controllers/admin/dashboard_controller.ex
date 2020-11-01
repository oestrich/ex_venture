defmodule Web.Admin.DashboardController do
  use Web, :controller

  plug(Web.Plugs.ActiveTab, tab: :dashboard)

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
