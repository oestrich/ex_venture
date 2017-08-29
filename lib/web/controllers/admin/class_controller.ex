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
end
