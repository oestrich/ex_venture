defmodule Kantele.Character.DelayedEvent do
  use Kalevala.Character.Event

  alias Kantele.Character.CommandController
  alias Kantele.Character.DelayedView

  def run(conn, %{data: %{"command" => command}}) do
    conn
    |> render(DelayedView, "display", %{command: command})
    |> CommandController.recv(command)
  end
end
