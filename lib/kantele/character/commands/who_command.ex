defmodule Kantele.Character.WhoCommand do
  use Kalevala.Character.Command

  alias Kantele.Character.WhoView
  alias Kantele.Character.Presence

  def run(conn, _params) do
    conn
    |> assign(:characters, Presence.characters())
    |> render(WhoView, "list")
  end
end
