defmodule Web.Admin.RaceController do
  use Web.AdminController

  alias Web.Race

  def index(conn, _params) do
    races = Race.all()
    conn |> render("index.html", races: races)
  end

  def show(conn, %{"id" => id}) do
    race = Race.get(id)
    conn |> render("show.html", race: race)
  end

  def new(conn, _params) do
    changeset = Race.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"race" => params}) do
    case Race.create(params) do
      {:ok, race} -> conn |> redirect(to: race_path(conn, :show, race.id))
      {:error, changeset} -> conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    race = Race.get(id)
    changeset = Race.edit(race)
    conn |> render("edit.html", race: race, changeset: changeset)
  end

  def update(conn, %{"id" => id, "race" => params}) do
    case Race.update(id, params) do
      {:ok, race} ->
        conn |> redirect(to: race_path(conn, :show, race.id))

      {:error, changeset} ->
        race = Race.get(id)
        conn |> render("edit.html", race: race, changeset: changeset)
    end
  end
end
