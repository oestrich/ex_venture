defmodule Game.SessionTest do
  use GenServerCase
  use Data.ModelCase

  alias Game.Session

  @socket Test.Networking.Socket

  setup do
    socket = :socket
    @socket.clear_messages
    user = %{name: "user"}
    {:ok, %{socket: socket, user: user, save: %{}}}
  end

  test "echoing messages", state = %{socket: socket} do
    {:noreply, ^state} = Session.handle_cast({:echo, "a message"}, state)

    assert @socket.get_echos() == [{socket, "a message"}]
    assert @socket.get_prompts() == [{socket, "> "}]
  end

  test "ticking", state do
    {:noreply, %{last_tick: :time}} = Session.handle_cast({:tick, :time}, state)
  end

  test "recv'ing messages - the first", %{socket: socket} do
    {:noreply, state} = Session.handle_cast({:recv, "name"}, %{socket: socket, state: "login"})

    assert @socket.get_prompts() == [{socket, "Password: "}]
    assert state.last_recv
  end

  test "recv'ing messages - after login processes commands", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    {:noreply, state} = Session.handle_cast({:recv, "quit"}, %{socket: socket, state: "active", user: user, save: %{room_id: 1}})

    assert @socket.get_echos() == [{socket, "Good bye."}]
    assert state.last_recv
  end

  test "checking for inactive players - not inactive", %{socket: socket} do
    {:noreply, _state} = Session.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now()})

    assert @socket.get_disconnects() == []
  end

  test "checking for inactive players - inactive", %{socket: socket} do
    {:noreply, _state} = Session.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now() |> Timex.shift(minutes: -6)})

    assert @socket.get_disconnects() == [socket]
  end

  test "unregisters the pid when disconnected" do
    Registry.register(Session.Registry, "player", :connected)

    {:stop, :normal, _state} = Session.handle_cast(:disconnect, %{user: %Data.User{name: "user"}, save: %{room_id: 1}})
    assert Registry.lookup(Session.Registry, "player") == []
  end

  test "applying effects", %{socket: socket} do
    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 25}
    user = %{name: "user"}

    {:noreply, state} = Session.handle_cast({:apply_effects, [effect], {:npc, %{name: "Bandit"}}, "description"}, %{socket: socket, state: "active", user: user, save: %{stats: stats}})
    assert state.save.stats.health == 15

    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}
  end
end
