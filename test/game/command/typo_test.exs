defmodule Game.Command.TypoTest do
  use Data.ModelCase
  import Ecto.Query

  alias Game.Command.Typo
  alias Game.Session.State

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    %{session: :session, socket: :socket}
  end

  test "creating a new typo", %{session: session, socket: socket} do
    {:editor, Typo, state} = Typo.run({"title"}, session, %{socket: socket})

    assert state.commands.typo.title == "title"
    assert state.commands.typo.lines == []

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(enter in any more), echo)
  end

  test "add lines together in the editor", %{socket: socket} do
    state = %State{socket: socket, state: "active", mode: "editor", commands: %{typo: %{lines: []}}}
    {:update, state} = Typo.editor({:text, "line"}, state)
    assert state.commands.typo.lines == ["line"]
  end

  test "complete the editor creates a typo", %{socket: socket} do
    zone = create_zone()
    room = create_room(zone)

    user = create_user(%{name: "user", password: "password"})

    typo = %{title: "A typo", lines: ["line 1", "line 2"]}
    state = %State{socket: socket, state: "active", mode: "editor", commands: %{typo: typo}, user: user, save: %{room_id: room.id}}
    {:update, state} = Typo.editor(:complete, state)

    assert state.commands == %{}

    assert Data.Typo |> select([b], count(b.id)) |> Repo.one == 1
  end

  test "complete the editor creates a typo - a typo with issues", %{socket: socket} do
    typo = %{title: "A typo", lines: ["line 1", "line 2"]}
    state = %State{socket: socket, state: "active", mode: "editor", commands: %{typo: typo}, user: %{id: -1}, save: %{room_id: -1}}
    {:update, state} = Typo.editor(:complete, state)

    assert state.commands == %{}

    assert Data.Typo |> select([b], count(b.id)) |> Repo.one == 0
    [{^socket, echo}] = @socket.get_echos()

    assert Regex.match?(~r(an issue), echo)
  end
end
