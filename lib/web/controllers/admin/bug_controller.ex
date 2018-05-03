defmodule Web.Admin.BugController do
  use Web.AdminController

  alias Web.Bug

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "bug", %{})
    %{page: bugs, pagination: pagination} = Bug.all(filter: filter, page: page, per: per)

    conn
    |> assign(:bugs, bugs)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    bug = Bug.get(id)

    conn
    |> assign(:bug, bug)
    |> render("show.html")
  end

  def complete(conn, %{"bug_id" => id}) do
    case Bug.complete(id) do
      {:ok, bug} ->
        conn
        |> put_flash(:info, "Bug marked as completed!")
        |> redirect(to: bug_path(conn, :show, bug))

      _ ->
        conn
        |> put_flash(:error, "There was an issue marking the bug as complete. Please try again.")
        |> redirect(to: bug_path(conn, :index))
    end
  end
end
