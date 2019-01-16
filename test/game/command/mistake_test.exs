defmodule Game.Command.MistakeTest do
  use ExVenture.CommandCase

  alias Game.Command.Mistake

  doctest Mistake

  setup do
    %{socket: :socket}
  end

  test "display a message about auto combat", %{socket: socket} do
    :ok = Mistake.run({:auto_combat}, %{socket: socket})

    assert_socket_echo "read.*help"
  end
end
