defmodule Game.Command.TypoTest do
  use Data.ModelCase
  import Ecto.Query

  alias Game.Command.Typo
  alias Game.Session.State

  @socket Test.Networking.Socket

  setup do
    @socket.clear_messages()

    state = %State{socket: :socket, state: "active", mode: "editor", commands: %{typo: %{lines: []}}}
    %{state: state}
  end

  describe "creating a new typo" do
    test "starting to create a new typo", %{state: state} do
      {:editor, Typo, state} = Typo.run({"title"}, state)

      assert state.commands.typo.title == "title"
      assert state.commands.typo.lines == []

      [{_socket, echo}] = @socket.get_echos()
      assert Regex.match?(~r(enter in any more), echo)
    end

    test "add lines together in the editor", %{state: state} do
      {:update, state} = Typo.editor({:text, "line"}, state)
      assert state.commands.typo.lines == ["line"]
    end

    test "complete the editor creates a typo", %{state: state}  do
      zone = create_zone()
      room = create_room(zone)

      user = create_user(%{name: "user", password: "password"})
      character = create_character(user, %{name: "user"})

      typo = %{title: "A typo", lines: ["line 1", "line 2"]}
      state = %{state | commands: %{typo: typo}, character: character, save: %{room_id: room.id}}

      {:update, state} = Typo.editor(:complete, state)

      assert state.commands == %{}

      assert Data.Typo |> select([b], count(b.id)) |> Repo.one == 1
    end

    test "complete the editor creates a typo - a typo with issues", %{state: state} do
      typo = %{title: "A typo", lines: ["line 1", "line 2"]}
      state = %{state | commands: %{typo: typo}, character: %{id: -1}, save: %{room_id: -1}}

      {:update, state} = Typo.editor(:complete, state)

      assert state.commands == %{}

      assert Data.Typo |> select([b], count(b.id)) |> Repo.one == 0
      [{_socket, echo}] = @socket.get_echos()

      assert Regex.match?(~r(an issue), echo)
    end
  end
end
