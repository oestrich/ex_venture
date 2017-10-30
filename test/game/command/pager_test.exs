defmodule Game.Command.PagerTest do
  use Data.ModelCase

  @socket Test.Networking.Socket

  alias Game.Command.Pager

  setup do
    @socket.clear_messages
    %{state: %{session: :session, socket: :socket}}
  end

  test "paginate text", %{state: state} do
    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Pager.paginate(state, lines: 2)

    assert state.mode == "paginate"
    assert state.pagination.text == "text"

    [{_, text}, {_, "Press enter to continue..."}] = @socket.get_echos()
    assert text == "Lines\nof"
  end

  test "stop paginate mode if out of text", %{state: state} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    state = Map.put(state, :pagination, %{text: "Lines\nof\ntext"})
    state = Map.put(state, :user, user)
    state = Map.put(state, :save, base_save())
    state = Pager.paginate(state, lines: 4)

    assert state.mode == "commands"
    refute Map.has_key?(state, :pagination)

    [{_, text}] = @socket.get_echos()
    assert text == "Lines\nof\ntext"
  end
end
