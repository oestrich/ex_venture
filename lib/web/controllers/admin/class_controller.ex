defmodule Web.Admin.ClassController do
  use Web.AdminController

  alias Web.Class

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: classes, pagination: pagination} = Class.all(page: page, per: per)

    conn
    |> assign(:classes, classes)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    class = Class.get(id)

    conn
    |> assign(:class, class)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Class.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"class" => params}) do
    case Class.create(params) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "#{class.name} created!")
        |> redirect(to: class_path(conn, :show, class.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the class. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    class = Class.get(id)
    changeset = Class.edit(class)

    conn
    |> assign(:class, class)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "class" => params}) do
    case Class.update(id, params) do
      {:ok, class} ->
        conn
        |> put_flash(:info, "#{class.name} updated!")
        |> redirect(to: class_path(conn, :show, class.id))

      {:error, changeset} ->
        class = Class.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{class.name}. Please try again.")
        |> assign(:class, class)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
