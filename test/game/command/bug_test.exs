defmodule Game.Command.BugTest do
  use Data.ModelCase
  import Ecto.Query

  alias Game.Command.Bug
  alias Game.Session.State

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages
    %{session: :session, socket: :socket}
  end

  test "creating a new bug", %{session: session, socket: socket} do
    {:editor, Bug, state} = Bug.run({"title"}, session, %{socket: socket})

    assert state.commands.bug.title == "title"
    assert state.commands.bug.lines == []

    [{^socket, echo}] = @socket.get_echos()
    assert Regex.match?(~r(enter in any more), echo)
  end

  test "add lines together in the editor", %{socket: socket} do
    state = %State{socket: socket, state: "active", mode: "editor", commands: %{bug: %{lines: []}}}
    {:update, state} = Bug.editor({:text, "line"}, state)
    assert state.commands.bug.lines == ["line"]
  end

  test "complete the editor creates a bug", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})

    bug = %{title: "A bug", lines: ["line 1", "line 2"]}
    state = %State{socket: socket, state: "active", mode: "editor", commands: %{bug: bug}, user: user}
    {:update, state} = Bug.editor(:complete, state)

    assert state.commands == %{}

    assert Data.Bug |> select([b], count(b.id)) |> Repo.one == 1
  end

  test "complete the editor creates a bug - a bug with bugs", %{socket: socket} do
    bug = %{title: "A bug", lines: ["line 1", "line 2"]}
    state = %State{socket: socket, state: "active", mode: "editor", commands: %{bug: bug}, user: %{id: -1}}
    {:update, state} = Bug.editor(:complete, state)

    assert state.commands == %{}

    assert Data.Bug |> select([b], count(b.id)) |> Repo.one == 0
    [{^socket, echo}] = @socket.get_echos()

    assert Regex.match?(~r(an issue), echo)
  end
end
