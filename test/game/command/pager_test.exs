defmodule Game.Command.PagerTest do
  use ExVenture.CommandCase

  alias Game.Command.Pager

  setup do
    user = create_user(%{name: "user", password: "password"})

    # for the prompt
    character = create_character(user)
    |> Repo.preload([class: [:skills]])

    %{state: session_state(%{user: user, character: character, save: character.save})}
  end

  test "paginate text", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 2)

    assert state.mode == "paginate"
    assert state.pagination.text == "text"

    assert_socket_echo "lines\nof"
    assert_socket_prompt "."
  end

  test "stop paginate mode if out of text", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 4)

    assert state.mode == "commands"
    refute Map.has_key?(state, :pagination)

    assert_socket_echo "lines\nof\ntext"
  end

  test "display all text at once", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 2, command: "all")

    assert state.mode == "commands"
    refute Map.has_key?(state, :pagination)

    assert_socket_echo "lines\nof\ntext"
  end

  test "quit pagination early", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 2, command: "quit")

    assert state.mode == "commands"
    refute Map.has_key?(state, :pagination)
  end
end
