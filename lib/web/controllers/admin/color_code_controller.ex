defmodule Web.Admin.ColorCodeController do
  use Web.AdminController

  alias Web.ColorCode

  def index(conn, _params) do
    color_codes = ColorCode.all()

    conn
    |> assign(:color_codes, color_codes)
    |> render("index.html")
  end

  def new(conn, _params) do
    changeset = ColorCode.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"color_code" => params}) do
    case ColorCode.create(params) do
      {:ok, color_code} ->
        conn
        |> put_flash(:info, "#{color_code.key} created!")
        |> redirect(to: color_code_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the color code. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    color_code = ColorCode.get(id)
    changeset = ColorCode.edit(color_code)

    conn
    |> assign(:color_code, color_code)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "color_code" => params}) do
    case ColorCode.update(id, params) do
      {:ok, color_code} ->
        conn
        |> put_flash(:info, "#{color_code.key} updated!")
        |> redirect(to: color_code_path(conn, :index))

      {:error, changeset} ->
        color_code = ColorCode.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{color_code.key}. Please try again.")
        |> assign(:color_code, color_code)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
