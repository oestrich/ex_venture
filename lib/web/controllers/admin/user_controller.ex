defmodule Web.Admin.UserController do
  use Web.AdminController

  plug(Web.Plug.FetchPage when action in [:index])
  plug(:ensure_admin!)

  alias Web.User

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "user", %{})
    %{page: users, pagination: pagination} = User.all(filter: filter, page: page, per: per)

    conn
    |> assign(:users, users)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    user = User.get(id)

    conn
    |> assign(:user, user)
    |> render("show.html")
  end

  def edit(conn, %{"id" => id}) do
    user = User.get(id)
    changeset = User.edit(user)

    conn
    |> assign(:user, user)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "user" => params}) do
    case User.update(id, params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "#{user.name} updated!")
        |> redirect(to: user_path(conn, :show, user.id))

      {:error, changeset} ->
        user = User.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{user.name}. Please try again.")
        |> assign(:user, user)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
