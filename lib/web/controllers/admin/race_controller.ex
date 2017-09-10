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
end
