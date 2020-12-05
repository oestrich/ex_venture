defmodule Kantele.Character.VersionCommand do
  use Kalevala.Character.Command

  alias Kantele.Character.VersionView

  def run(conn, _params) do
    conn
    |> assign(:kalevala_version, Kalevala.version())
    |> render(VersionView, "show")
  end
end
