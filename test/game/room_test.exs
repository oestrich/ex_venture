defmodule Game.RoomTest do
  use Data.ModelCase

  alias Game.Room

  setup do
    {:ok, user: %{username: "user"}}
  end

  test "entering a room", %{user: user} do
    {:noreply, state} = Room.handle_cast({:enter, {:user, :session, user}}, %{players: []})
    assert state.players == [{:user, :session, user}]
  end

  test "leaving a room", %{user: user} do
    {:noreply, state} = Room.handle_cast({:leave, {:user, :session, user}}, %{players: [{:user, :session, user}]})
    assert state.players == []
  end
end
