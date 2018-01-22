defmodule Game.Command.PagerTest do
  use Data.ModelCase

  @socket Test.Networking.Socket

  alias Game.Command.Pager

  setup do
    @socket.clear_messages

    # for the prompt
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    state = %{
      socket: :socket,
      user: user,
      save: base_save(),
    }

    %{state: state}
  end

  test "paginate text", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 2)

    assert state.mode == "paginate"
    assert state.pagination.text == "text"

    [{_, text}] = @socket.get_echos()
    assert text == "Lines\nof"

    assert @socket.get_prompts() |> length() == 1
  end

  test "stop paginate mode if out of text", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 4)

    assert state.mode == "commands"
    refute Map.has_key?(state, :pagination)

    [{_, text}] = @socket.get_echos()
    assert text == "Lines\nof\ntext"
  end

  test "display all text at once", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 2, command: "all")

    assert state.mode == "commands"
    refute Map.has_key?(state, :pagination)

    [{_, text}] = @socket.get_echos()
    assert text == "Lines\nof\ntext"
  end

  test "quit pagination early", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 2, command: "quit")

    assert state.mode == "commands"
    refute Map.has_key?(state, :pagination)
  end
end
