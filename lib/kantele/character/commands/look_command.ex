defmodule Kantele.Character.LookCommand do
  use Kalevala.Character.Command

  def run(conn, _params) do
    conn
    |> event("room/look")
    |> assign(:prompt, false)
  end
end
