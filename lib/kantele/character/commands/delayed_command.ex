defmodule Kantele.Character.DelayedCommand do
  use Kalevala.Character.Command

  def run(conn, %{"command" => command}) do
    delay_event(conn, 5000, "commands/delayed", %{"command" => command})
  end
end
