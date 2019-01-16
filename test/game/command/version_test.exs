defmodule Game.Command.VersionTest do
  use ExVenture.CommandCase

  alias Game.Command.Version

  doctest Version

  setup do
    %{state: session_state(%{})}
  end

  test "view the version", %{state: state} do
    :ok = Version.run({}, state)

    assert_socket_echo "ExVenture v"
  end
end
