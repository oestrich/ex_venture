defmodule Game.Command.BugTest do
  use ExVenture.CommandCase

  import Ecto.Query

  alias Game.Command.Bug

  doctest Bug

  describe "viewing a list of your bugs" do
    setup do
      user = create_user(%{name: "user", password: "password"})
      character = create_character(user, %{name: "Player"})
      %{state: session_state(%{user: user, character: character})}
    end

    test "shows all", %{state: state} do
      create_bug(state.character, %{title: "my bug", description: "some extras"})

      :ok = Bug.run({:list}, state)

      assert_socket_echo "my bug"
    end

    test "view a single bug", %{state: state} do
      bug = create_bug(state.character, %{title: "my bug", description: "some extras"})

      :ok = Bug.run({:read, to_string(bug.id)}, state)

      assert_socket_echo "my bug"
    end
  end

  describe "documenting a bug" do
    setup do
      user = create_user(%{name: "user", password: "password"})
      character = create_character(user, %{name: "Player"})
      %{state: session_state(%{mode: "editor", user: user, character: character})}
    end

    test "creating a new bug", %{state: state} do
      state = %{state | commands: %{bug: %{lines: []}}}

      {:editor, Bug, state} = Bug.run({:new, "title"}, state)

      assert state.commands.bug.title == "title"
      assert state.commands.bug.lines == []
      assert_socket_echo "enter in any more"
    end

    test "add lines together in the editor", %{state: state} do
      state = %{state | commands: %{bug: %{lines: []}}}

      {:update, state} = Bug.editor({:text, "line"}, state)

      assert state.commands.bug.lines == ["line"]
    end

    test "complete the editor creates a bug", %{state: state} do
      bug = %{title: "A bug", lines: ["line 1", "line 2"]}
      state = %{state | commands: %{bug: bug}}
      {:update, state} = Bug.editor(:complete, state)

      assert state.commands == %{}
      assert Data.Bug |> select([b], count(b.id)) |> Repo.one == 1
    end

    test "complete the editor creates a bug - a bug with bugs", %{state: state} do
      bug = %{title: "A bug", lines: ["line 1", "line 2"]}
      state = %{state | commands: %{bug: bug}, character: %{id: -1}}
      {:update, state} = Bug.editor(:complete, state)

      assert state.commands == %{}
      assert Data.Bug |> select([b], count(b.id)) |> Repo.one == 0
      assert_socket_echo "an issue"
    end
  end
end
