defmodule Web.Admin.BugController do
  use Web.AdminController

  alias Web.Bug

  plug Web.Plug.FetchPage when action in [:index]

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: bugs, pagination: pagination} = Bug.all(page: page, per: per)
    conn |> render("index.html", bugs: bugs, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    bug = Bug.get(id)
    conn |> render("show.html", bug: bug)
  end
end
