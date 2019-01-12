defmodule Web.Admin.ProficiencyController do
  use Web.AdminController

  plug(:ensure_admin!)

  alias Web.Proficiency

  def index(conn, _params) do
    proficiencies = Proficiency.all()

    conn
    |> assign(:proficiencies, proficiencies)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, proficiency} <- Proficiency.get(id) do
      conn
      |> assign(:proficiency, proficiency)
      |> render("show.html")
    end
  end

  def new(conn, _params) do
    changeset = Proficiency.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"proficiency" => params}) do
    case Proficiency.create(params) do
      {:ok, proficiency} ->
        conn
        |> put_flash(:info, "#{proficiency.name} created!")
        |> redirect(to: proficiency_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the proficiency. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    with {:ok, proficiency} <- Proficiency.get(id) do
      changeset = Proficiency.edit(proficiency)

      conn
      |> assign(:proficiency, proficiency)
      |> assign(:changeset, changeset)
      |> render("edit.html")
    end
  end

  def update(conn, %{"id" => id, "proficiency" => params}) do
    {:ok, proficiency} = Proficiency.get(id)

    with {:ok, proficiency} <- Proficiency.update(proficiency, params) do
      conn
      |> put_flash(:info, "#{proficiency.name} updated!")
      |> redirect(to: proficiency_path(conn, :index))
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue updating #{proficiency.name}. Please try again.")
        |> assign(:proficiency, proficiency)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
