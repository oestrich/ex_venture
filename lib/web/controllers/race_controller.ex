defmodule Web.RaceController do
  use Web, :controller

  alias Web.Race

  def index(conn, _params) do
    races = Race.all(alpha: true)
    conn
    |> assign(:races, races)
    |> render(:index)
  end

  def show(conn, %{"id" => id}) do
    case Race.get(id) do
      nil ->
        conn |> redirect(to: public_page_path(conn, :index))

      race ->
        conn
        |> assign(:race, race)
        |> assign(:extended, true)
        |> render(:show)
    end
  end
end
