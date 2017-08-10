defmodule Game.Command.SkillsTest do
  use Data.ModelCase

  alias Game.Command

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    slash = %{name: "Slash", command: "slash", description: "Slash at your target"}
    user = %{class: %{name: "Fighter", skills: [slash]}}
    {:ok, %{session: :session, socket: :socket, user: user}}
  end

  test "view room information", %{session: session, socket: socket, user: user} do
    Command.Skills.run({}, session, %{socket: socket, user: user})

    [{^socket, look}] = @socket.get_echos()
    assert Regex.match?(~r(slash), look)
  end
end
