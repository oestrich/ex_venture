defmodule Web.Admin.ColorController do
  use Web.AdminController

  alias Web.Color
  alias Web.ColorCode

  def index(conn, _params) do
    color_codes = ColorCode.all()

    conn
    |> assign(:color_codes, color_codes)
    |> render("index.html")
  end

  def update(conn, %{"colors" => params}) do
    Color.update(params)

    conn
    |> put_flash(:info, "Colors updated!")
    |> redirect(to: color_path(conn, :index))
  end

  def delete(conn, _params) do
    Color.reset()

    conn
    |> put_flash(:info, "Colors reset!")
    |> redirect(to: color_path(conn, :index))
  end
end
