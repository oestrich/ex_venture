defmodule Kantele.Character.InfoCommand do
  use Kalevala.Character.Command

  alias Kantele.Character.InfoView

  def run(conn, _params) do
    render(conn, InfoView, "display")
  end
end
