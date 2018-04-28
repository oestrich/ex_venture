defmodule Web.ClassController do
  use Web, :controller

  alias Web.Class

  def index(conn, _params) do
    classes = Class.all(alpha: true)

    conn
    |> assign(:classes, classes)
    |> render(:index)
  end

  def show(conn, %{"id" => id}) do
    case Class.get(id) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))

      class ->
        conn
        |> assign(:class, class)
        |> assign(:extended, true)
        |> render(:show)
    end
  end
end
