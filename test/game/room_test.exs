defmodule Game.RoomTest do
  use ExUnit.Case

  alias Game.Room

  setup do
    {:ok, user: %{}}
  end

  test "entering a room", %{user: user} do
    {:noreply, state} = Room.handle_cast({:enter, user}, %{players: []})
    assert state.players == [user]
  end

  test "leaving a room", %{user: user} do
    {:noreply, state} = Room.handle_cast({:leave, user}, %{players: [user]})
    assert state.players == []
  end
end
