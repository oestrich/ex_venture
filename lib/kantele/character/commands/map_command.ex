defmodule Kantele.Character.MapCommand do
  use Kalevala.Character.Command

  def run(conn, _params) do
    event(conn, "zone-map/look")
  end
end
