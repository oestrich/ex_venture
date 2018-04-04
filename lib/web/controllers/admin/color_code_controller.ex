defmodule Web.Admin.ColorCodeController do
  use Web.AdminController

  alias Web.ColorCode

  def index(conn, _params) do
    color_codes = ColorCode.all()
    conn |> render("index.html", color_codes: color_codes)
  end

  def new(conn, _params) do
    changeset = ColorCode.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"color_code" => params}) do
    case ColorCode.create(params) do
      {:ok, _color_code} ->
        conn |> redirect(to: color_code_path(conn, :index))

      {:error, changeset} ->
        conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    color_code = ColorCode.get(id)
    changeset = ColorCode.edit(color_code)
    conn |> render("edit.html", color_code: color_code, changeset: changeset)
  end

  def update(conn, %{"id" => id, "color_code" => params}) do
    case ColorCode.update(id, params) do
      {:ok, _color_code} ->
        conn |> redirect(to: color_code_path(conn, :index))

      {:error, changeset} ->
        color_code = ColorCode.get(id)
        conn |> render("edit.html", color_code: color_code, changeset: changeset)
    end
  end
end
