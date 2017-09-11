defmodule Web.ClassController do
  use Web, :controller

  alias Web.Class

  def index(conn, _params) do
    classes = Class.all(alpha: true)
    conn |> render("index.html", classes: classes)
  end

  def show(conn, %{"id" => id}) do
    class = Class.get(id)
    conn |> render("show.html", class: class)
  end
end
