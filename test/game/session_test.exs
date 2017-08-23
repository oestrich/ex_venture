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

  describe "ticking" do
    setup do
      stats = %{health: 10, max_health: 15, skill_points: 9, max_skill_points: 12}
      %{user: %{class: %{points_name: "Skill Points"}}, save: %{stats: stats}, regen: %{count: 5}}
    end

    test "updates last tick", state do
      {:noreply, %{last_tick: :time}} = Session.handle_cast({:tick, :time}, state)
    end

    test "regens stats", state do
      {:noreply, %{regen: %{count: 0}, save: %{stats: stats}}} = Session.handle_cast({:tick, :time}, state)

      assert stats.health == 11
      assert stats.skill_points == 10

      assert_received {:"$gen_cast", {:echo, ~s(You regenerated some health and skill points.)}}
    end

    test "does not echo if stats did not change", state do
      stats = %{health: 15, max_health: 15, skill_points: 12, max_skill_points: 12}

      {:noreply, %{save: %{stats: stats}}} = Session.handle_cast({:tick, :time}, %{state | save: %{stats: stats}})

      assert stats.health == 15
      assert stats.skill_points == 12

      refute_received {:"$gen_cast", {:echo, ~s(You regenerated some health and skill points.)}}
    end

    test "does not regen, only increments count if not high enough", state do
      {:noreply, %{regen: %{count: 2}, save: %{stats: stats}}} = Session.handle_cast({:tick, :time}, %{state | regen: %{count: 1}})

      assert stats.health == 10
      assert stats.skill_points == 9
    end
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

    state = %{socket: socket, state: "active", user: user, save: %{stats: stats}, is_targeting: MapSet.new}
    {:noreply, state} = Session.handle_cast({:apply_effects, [effect], {:npc, %{name: "Bandit"}}, "description"}, state)
    assert state.save.stats.health == 15

    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}
  end

  test "applying effects - died", %{socket: socket} do
    Session.Registry.register(%{id: 2})

    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 5}
    user = %{name: "user"}

    is_targeting = MapSet.new() |> MapSet.put({:user, 2})
    state = %{socket: socket, state: "active", user: user, save: %{stats: stats}, is_targeting: is_targeting}
    {:noreply, state} = Session.handle_cast({:apply_effects, [effect], {:npc, %{name: "Bandit"}}, "description"}, state)
    assert state.save.stats.health == -5

    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}
    assert_received {:"$gen_cast", {:died, {:user, _}}}

    Session.Registry.unregister()
  end

  test "being targeted tracks the targeter", %{socket: socket} do
    targeter = {:user, %{id: 10, name: "Player"}}

    {:noreply, state} = Session.handle_cast({:targeted, targeter}, %{socket: socket, is_targeting: MapSet.new})

    assert state.is_targeting |> MapSet.size() == 1
    assert state.is_targeting |> MapSet.member?({:user, 10})
  end

  test "a player removing a target stops tracking them", %{socket: socket} do
    targeter = {:user, %{id: 10, name: "Player"}}
    is_targeting = MapSet.new() |> MapSet.put({:user, 10})

    {:noreply, state} = Session.handle_cast({:remove_target, targeter}, %{socket: socket, is_targeting: is_targeting})

    assert state.is_targeting |> MapSet.size() == 0
    refute state.is_targeting |> MapSet.member?({:user, 10})
  end

  test "a died message is sent" do
    target = {:user, %{id: 10, name: "Player"}}

    {:noreply, state} = Session.handle_cast({:died, target}, %{state: "active", target: {:user, 10}})

    assert is_nil(state.target)
  end
end
