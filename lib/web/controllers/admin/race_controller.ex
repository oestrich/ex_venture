defmodule Web.Admin.RaceController do
  use Web.AdminController

  alias Web.Race

  def index(conn, _params) do
    races = Race.all()

    conn
    |> assign(:races, races)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    race = Race.get(id)

    conn
    |> assign(:race, race)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Race.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"race" => params}) do
    case Race.create(params) do
      {:ok, race} ->
        conn
        |> put_flash(:info, "#{race.name} created!")
        |> redirect(to: race_path(conn, :show, race.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the race. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    race = Race.get(id)
    changeset = Race.edit(race)

    conn
    |> assign(:race, race)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "race" => params}) do
    case Race.update(id, params) do
      {:ok, race} ->
        conn
        |> put_flash(:info, "#{race.name} updated!")
        |> redirect(to: race_path(conn, :show, race.id))

      {:error, changeset} ->
        race = Race.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{race.name}. Please try again.")
        |> assign(:race, race)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
