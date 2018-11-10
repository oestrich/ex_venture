defmodule Web.Admin.RoleController do
  use Web.AdminController

  alias Web.Role

  def index(conn, _params) do
    conn
    |> assign(:roles, Role.all())
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    role = Role.get(id)

    conn
    |> assign(:role, role)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Role.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"role" => params}) do
    case Role.create(params) do
      {:ok, role} ->
        conn
        |> put_flash(:info, "#{role.name} created!")
        |> redirect(to: role_path(conn, :show, role.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the role. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    role = Role.get(id)
    changeset = Role.edit(role)

    conn
    |> assign(:role, role)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "role" => params}) do
    case Role.update(id, params) do
      {:ok, role} ->
        conn
        |> put_flash(:info, "#{role.name} updated!")
        |> redirect(to: role_path(conn, :show, role.id))

      {:error, changeset} ->
        role = Role.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{role.name}. Please try again.")
        |> assign(:role, role)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
