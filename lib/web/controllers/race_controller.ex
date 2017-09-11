defmodule Web.RaceController do
  use Web, :controller

  alias Web.Race

  def index(conn, _params) do
    races = Race.all(alpha: true)
    conn |> render("index.html", races: races)
  end

  def show(conn, %{"id" => id}) do
    race = Race.get(id)
    conn |> render("show.html", race: race)
  end
end
