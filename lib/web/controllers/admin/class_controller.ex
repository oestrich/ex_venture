defmodule Web.Admin.ClassController do
  use Web.AdminController

  alias Web.Class

  def index(conn, _params) do
    classes = Class.all()
    conn |> render("index.html", classes: classes)
  end

  def show(conn, %{"id" => id}) do
    class = Class.get(id)
    conn |> render("show.html", class: class)
  end

  def new(conn, _params) do
    changeset = Class.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"class" => params}) do
    case Class.create(params) do
      {:ok, class} -> conn |> redirect(to: class_path(conn, :show, class.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end
end
