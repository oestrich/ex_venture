defmodule Web.Admin.BugController do
  use Web.AdminController

  alias Web.Bug

  plug Web.Plug.FetchPage when action in [:index]

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "bug", %{})
    %{page: bugs, pagination: pagination} = Bug.all(filter: filter, page: page, per: per)
    conn |> render("index.html", bugs: bugs, filter: filter, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    bug = Bug.get(id)
    conn |> render("show.html", bug: bug)
  end

  def complete(conn, %{"bug_id" => id}) do
    case Bug.complete(id) do
      {:ok, bug} ->
        conn |> redirect(to: bug_path(conn, :show, bug))
      _ ->
        conn |> redirect(to: bug_path(conn, :index))
    end
  end
end
