defmodule Kantele.Character.WanderEvent do
  use Kalevala.Character.Event

  def run(conn, %{data: %{exits: exits}}) do
    exit_name = Enum.random(exits)
    request_movement(conn, exit_name)
  end
end
