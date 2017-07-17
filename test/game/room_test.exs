defmodule Game.RoomTest do
  use ExUnit.Case

  alias Game.Room

  setup do
    {:ok, user: %{username: "user"}}
  end

  test "entering a room", %{user: user} do
    {:noreply, state} = Room.handle_cast({:enter, {:session, user}}, %{players: []})
    assert state.players == [{:session, user}]
  end

  test "leaving a room", %{user: user} do
    {:noreply, state} = Room.handle_cast({:leave, {:session, user}}, %{players: [{:session, user}]})
    assert state.players == []
  end
end
