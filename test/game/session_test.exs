defmodule Game.SessionTest do
  use GenServerCase
  use Data.ModelCase

  alias Game.Session

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    socket = :socket
    @socket.clear_messages

    user = %{name: "user"}
    {:ok, %{socket: socket, user: user, save: %{}}}
  end

  test "echoing messages", state = %{socket: socket} do
    {:noreply, ^state} = Session.handle_cast({:echo, "a message"}, state)

    assert @socket.get_echos() == [{socket, "a message"}]
  end

  describe "ticking" do
    setup do
      stats = %{health: 10, max_health: 15, skill_points: 9, max_skill_points: 12, move_points: 8, max_move_points: 10}
      class = %{points_name: "Skill Points", regen_health: 1, regen_skill_points: 1}
      %{user: %{class: class}, save: %{room_id: 1, stats: stats}, regen: %{count: 5}}
    end

    test "updates last tick", state do
      {:noreply, %{last_tick: :time}} = Session.handle_cast({:tick, :time}, state)
    end

    test "regens stats", state do
      @room.clear_update_characters()

      {:noreply, %{regen: %{count: 0}, save: %{stats: stats}}} = Session.handle_cast({:tick, :time}, state)

      assert stats.health == 11
      assert stats.skill_points == 10
      assert stats.move_points == 9

      assert_received {:"$gen_cast", {:echo, ~s(You regenerated some health and skill points.)}}

      assert @room.get_update_characters() |> length() == 2
    end

    test "does not echo if stats did not change", state do
      stats = %{health: 15, max_health: 15, skill_points: 12, max_skill_points: 12, move_points: 10, max_move_points: 10}

      {:noreply, %{save: %{stats: stats}}} = Session.handle_cast({:tick, :time}, %{state | save: %{room_id: 1, stats: stats}})

      assert stats.health == 15
      assert stats.skill_points == 12
      assert stats.move_points == 10

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

    state = %{socket: socket, state: "active", blocked: false, user: user, save: %{room_id: 1}}
    {:noreply, state} = Session.handle_cast({:recv, "quit"}, state)

    assert @socket.get_echos() == [{socket, "Good bye."}]
    assert state.last_recv
  after
    Session.Registry.unregister()
  end

  test "processing a command that has continued commands", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
    state = %{socket: socket, state: "active", blocked: false, user: user, save: %{room_id: 1, stats: %{move_points: 10}}}
    {:noreply, state} = Session.handle_cast({:recv, "run 2n"}, state)

    assert state.blocked
    assert_receive {:continue, {Game.Command.Run, {[:north]}}}
  after
    Session.Registry.unregister()
  end

  test "continuing with processed commands", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
    state = %{socket: socket, user: user, save: %{room_id: 1, stats: %{move_points: 10}}}
    {:noreply, _state} = Session.handle_info({:continue, {Game.Command.Run, {[:north, :north]}}}, state)

    assert_receive {:continue, {Game.Command.Run, {[:north]}}}
  after
    Session.Registry.unregister()
  end

  test "does not process commands while input is blocked", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    state = %{socket: socket, state: "active", blocked: true, user: user, save: %{room_id: 1}}
    {:noreply, state} = Session.handle_cast({:recv, "say Hello"}, state)

    assert state.blocked
    assert @socket.get_echos() == []
  after
    Session.Registry.unregister()
  end

  test "user is not signed in yet does not save" do
    assert {:noreply, %{}} = Session.handle_info(:save, %{})
  end

  test "save the user's save" do
    user = create_user(%{name: "player", password: "password"})
    save = %{user.save | stats: %{user.save.stats | health: 10}}

    {:noreply, _state} = Session.handle_info(:save, %{user: user, save: save})

    user = Data.User |> Data.Repo.get(user.id)
    assert user.save.stats.health == 10
  end

  test "checking for inactive players - not inactive", %{socket: socket} do
    {:noreply, _state} = Session.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now()})

    assert @socket.get_disconnects() == []
  end

  test "checking for inactive players - inactive", %{socket: socket} do
    {:noreply, _state} = Session.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now() |> Timex.shift(minutes: -66)})

    assert @socket.get_disconnects() == [socket]
  end

  describe "disconnects" do
    test "unregisters the pid when disconnected" do
      user = %Data.User{name: "user", seconds_online: 0}
      Session.Registry.register(user)

      state = %{user: user, save: %{room_id: 1}, session_started_at: Timex.now()}
      {:stop, :normal, _state} = Session.handle_cast(:disconnect, state)
      assert Session.Registry.connected_players == []
    after
      Session.Registry.unregister()
    end

    test "adds the time played" do
      user = create_user(%{name: "user", password: "password"})
      state = %{user: user, save: user.save, session_started_at: Timex.now() |> Timex.shift(hours: -3)}

      {:stop, :normal, _state} = Session.handle_cast(:disconnect, state)

      user = Repo.get(Data.User, user.id)
      assert user.seconds_online == 10800
    end
  end

  test "applying effects", %{socket: socket} do
    @room.clear_update_characters()

    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 25}
    user = %{name: "user"}

    state = %{socket: socket, state: "active", user: user, save: %{room_id: 1, stats: stats}, is_targeting: MapSet.new}
    {:noreply, state} = Session.handle_cast({:apply_effects, [effect], {:npc, %{name: "Bandit"}}, "description"}, state)
    assert state.save.stats.health == 15

    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}

    assert [{1, {:user, _,  %{name: "user", save: %{room_id: 1, stats: %{health: 15}}}}}] = @room.get_update_characters()
  end

  test "applying effects - died", %{socket: socket} do
    Session.Registry.register(%{id: 2})

    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 5}
    user = %{name: "user"}

    is_targeting = MapSet.new() |> MapSet.put({:user, 2})
    state = %{socket: socket, state: "active", user: user, save: %{room_id: 1, stats: stats}, is_targeting: is_targeting}
    {:noreply, state} = Session.handle_cast({:apply_effects, [effect], {:npc, %{name: "Bandit"}}, "description"}, state)
    assert state.save.stats.health == -5

    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}
    assert_received {:"$gen_cast", {:died, {:user, _}}}
  after
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

  test "a died message is sent", %{socket: socket} do
    target = {:user, %{id: 10, name: "Player"}}
    user = %{id: 10}

    state = %{socket: socket, state: "active", user: user, save: %{}, target: {:user, 10}}
    {:noreply, state} = Session.handle_cast({:died, target}, state)

    assert is_nil(state.target)
  end

  test "npc - a died message is sent and experience is applied", %{socket: socket} do
    target = {:npc, %{id: 10, name: "Bandit", level: 1, experience_points: 1200}}
    user = %{id: 10, class: class_attributes(%{})}
    save = base_save()

    state = %{socket: socket, state: "active", user: user, save: save, target: {:npc, 10}}
    {:noreply, state} = Session.handle_cast({:died, target}, state)

    assert is_nil(state.target)
    assert state.save.level == 2
  end

  describe "channels" do
    setup do
      @socket.clear_messages()

      %{from: %{id: 10, name: "Player"}}
    end

    test "receiving a tell", %{socket: socket, from: from} do
      {:noreply, state} = Session.handle_info({:channel, {:tell, from, "howdy"}}, %{socket: socket})

      assert @socket.get_echos() == [{socket, "howdy"}]
      assert state.reply_to == from
    end

    test "receiving a join" do
      {:noreply, state} = Session.handle_info({:channel, {:joined, "global"}}, %{save: %{channels: ["newbie"]}})
      assert state.save.channels == ["global", "newbie"]
    end

    test "does not duplicate channels list" do
      {:noreply, state} = Session.handle_info({:channel, {:joined, "newbie"}}, %{save: %{channels: ["newbie"]}})
      assert state.save.channels == ["newbie"]
    end

    test "receiving a leave" do
      {:noreply, state} = Session.handle_info({:channel, {:left, "global"}}, %{save: %{channels: ["global", "newbie"]}})
      assert state.save.channels == ["newbie"]
    end
  end

  describe "teleport" do
    setup do
      user = create_user(%{name: "user", password: "password"})
      |> Repo.preload([:race, :class])
      zone = create_zone()
      room = create_room(zone)

      %{user: user, room: room}
    end

    test "teleports the user", %{socket: socket, user: user, room: room} do
      {:noreply, state} = Session.handle_cast({:teleport, room.id}, %{socket: socket, user: user, save: user.save})
      assert state.save.room_id == room.id
    end
  end
end
