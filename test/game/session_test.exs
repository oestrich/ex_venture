defmodule Game.SessionTest do
  use GenServerCase
  use Data.ModelCase

  alias Game.Command
  alias Game.Message
  alias Game.Session
  alias Game.Session.Process
  alias Game.Session.State

  @socket Test.Networking.Socket
  @room Test.Game.Room
  @zone Test.Game.Zone

  setup do
    socket = :socket
    @socket.clear_messages

    user = %{id: 1, name: "user"}
    {:ok, %{socket: socket, user: user, save: %{}}}
  end

  test "echoing messages", state = %{socket: socket} do
    {:noreply, ^state} = Process.handle_cast({:echo, "a message"}, state)

    assert @socket.get_echos() == [{socket, "a message"}]
  end

  describe "ticking" do
    setup do
      stats = %{health: 10, max_health: 15, skill_points: 9, max_skill_points: 12, move_points: 8, max_move_points: 10}
      class = %{points_name: "Skill Points", points_abbreviation: "SP", regen_health: 1, regen_skill_points: 1}
      %{user: %{class: class}, save: %{room_id: 1, level: 2, stats: stats}, regen: %{count: 5}}
    end

    test "updates last tick", state do
      {:noreply, %{last_tick: :time}} = Process.handle_cast({:tick, :time}, state)
    end

    test "regens stats", state do
      @room.clear_update_characters()

      {:noreply, %{regen: %{count: 0}, save: %{stats: stats}}} = Process.handle_cast({:tick, :time}, state)

      assert stats.health == 12
      assert stats.skill_points == 11
      assert stats.move_points == 9

      assert_received {:"$gen_cast", {:echo, ~s(You regenerated some health and skill points.)}}

      assert @room.get_update_characters() |> length() == 2
    end

    test "does not echo if stats did not change", state do
      stats = %{health: 15, max_health: 15, skill_points: 12, max_skill_points: 12, move_points: 10, max_move_points: 10}
      save = %{room_id: 1, level: 2, stats: stats}

      {:noreply, %{save: %{stats: stats}}} = Process.handle_cast({:tick, :time}, %{state | save: save})

      assert stats.health == 15
      assert stats.skill_points == 12
      assert stats.move_points == 10

      refute_received {:"$gen_cast", {:echo, ~s(You regenerated some health and skill points.)}}
    end

    test "does not regen, only increments count if not high enough", state do
      {:noreply, %{regen: %{count: 2}, save: %{stats: stats}}} = Process.handle_cast({:tick, :time}, %{state | regen: %{count: 1}})

      assert stats.health == 10
      assert stats.skill_points == 9
    end
  end

  test "recv'ing messages - the first", %{socket: socket} do
    {:noreply, state} = Process.handle_cast({:recv, "name"}, %{socket: socket, state: "login"})

    assert @socket.get_prompts() == [{socket, "Password: "}]
    assert state.last_recv
  end

  test "recv'ing messages - after login processes commands", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    state = %State{socket: socket, state: "active", mode: "commands", user: user, save: %{room_id: 1, stats: %{}}}
    {:noreply, state} = Process.handle_cast({:recv, "quit"}, state)

    assert @socket.get_echos() == [{socket, "Good bye."}]
    assert state.last_recv
  after
    Session.Registry.unregister()
  end

  test "processing a command that has continued commands", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
    state = %State{socket: socket, state: "active", mode: "commands", user: user, save: %{room_id: 1, stats: %{move_points: 10}}}
    {:noreply, state} = Process.handle_cast({:recv, "run 2n"}, state)

    assert state.mode == "continuing"
    assert_receive {:continue, %Command{module: Command.Run, args: {[:north]}}}
  after
    Session.Registry.unregister()
  end

  test "continuing with processed commands", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    @room.set_room(%Data.Room{id: 1, name: "", description: "", exits: [%{north_id: 2, south_id: 1}], players: [], shops: []})
    state = %State{socket: socket, state: "active", mode: "continuing", user: user, save: %{room_id: 1, stats: %{move_points: 10}}}
    command = %Command{module: Command.Run, args: {[:north, :north]}}
    {:noreply, _state} = Process.handle_info({:continue, command}, state)

    assert_receive {:continue, %Command{module: Command.Run, args: {[:north]}}}
  after
    Session.Registry.unregister()
  end

  test "does not process commands while mode is continuing", %{socket: socket} do
    user = create_user(%{name: "user", password: "password"})
    |> Repo.preload([class: [:skills]])

    state = %{socket: socket, state: "active", mode: "continuing", user: user, save: %{room_id: 1}}
    {:noreply, state} = Process.handle_cast({:recv, "say Hello"}, state)

    assert state.mode == "continuing"
    assert @socket.get_echos() == []
  after
    Session.Registry.unregister()
  end

  test "user is not signed in yet does not save" do
    assert {:noreply, %{}} = Process.handle_info(:save, %{})
  end

  test "save the user's save" do
    user = create_user(%{name: "player", password: "password"})
    save = %{user.save | stats: %{user.save.stats | health: 10}}

    {:noreply, _state} = Process.handle_info(:save, %{state: "active", user: user, save: save, session_started_at: Timex.now()})

    user = Data.User |> Data.Repo.get(user.id)
    assert user.save.stats.health == 10
  end

  test "checking for inactive players - not inactive", %{socket: socket} do
    {:noreply, _state} = Process.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now()})

    assert @socket.get_disconnects() == []
  end

  test "checking for inactive players - inactive", %{socket: socket} do
    {:noreply, _state} = Process.handle_info(:inactive_check, %{socket: socket, last_recv: Timex.now() |> Timex.shift(minutes: -66)})

    assert @socket.get_disconnects() == [socket]
  end

  describe "disconnects" do
    test "unregisters the pid when disconnected" do
      user = %Data.User{name: "user", seconds_online: 0}
      Session.Registry.register(user)

      state = %{user: user, save: %{room_id: 1}, session_started_at: Timex.now(), stats: %{}}
      {:stop, :normal, _state} = Process.handle_cast(:disconnect, state)
      assert Session.Registry.connected_players == []
    after
      Session.Registry.unregister()
    end

    test "adds the time played" do
      user = create_user(%{name: "user", password: "password"})
      state = %{user: user, save: user.save, session_started_at: Timex.now() |> Timex.shift(hours: -3), stats: %{}}

      {:stop, :normal, _state} = Process.handle_cast(:disconnect, state)

      user = Repo.get(Data.User, user.id)
      assert user.seconds_online == 10800
    end
  end

  test "applying effects", %{socket: socket} do
    @room.clear_update_characters()

    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 25}
    user = %{id: 2, name: "user", class: class_attributes(%{})}

    state = %State{socket: socket, state: "active", mode: "commands", user: user, save: %{room_id: 1, stats: stats}, is_targeting: MapSet.new}
    {:noreply, state} = Process.handle_cast({:apply_effects, [effect], {:npc, %{id: 1, name: "Bandit"}}, "description"}, state)
    assert state.save.stats.health == 15

    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}

    assert [{1, {:user, _,  %{name: "user", save: %{room_id: 1, stats: %{health: 15}}}}}] = @room.get_update_characters()
  end

  test "applying effects with continuous effects", %{socket: socket} do
    @room.clear_update_characters()

    effect = %{kind: "damage/over-time", type: :slashing, every: 10, count: 3, amount: 10}
    stats = %{health: 25}
    user = %{id: 2, name: "user", class: class_attributes(%{})}
    state = %State{socket: socket, state: "active", mode: "commands", user: user, save: %{room_id: 1, stats: stats}, is_targeting: MapSet.new()}

    {:noreply, state} = Process.handle_cast({:apply_effects, [effect], {:npc, %{id: 1, name: "Bandit"}}, "description"}, state)

    assert state.save.stats.health == 15
    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}

    [effect] = state.continuous_effects
    assert effect.kind == "damage/over-time"
    assert effect.id
    effect_id = effect.id
    assert_receive {:continuous_effect, ^effect_id}
  end

  test "applying effects - died", %{socket: socket} do
    Session.Registry.register(%{id: 2})

    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 5}
    user = %{id: 2, name: "user", class: class_attributes(%{})}

    is_targeting = MapSet.new() |> MapSet.put({:user, 2})
    state = %State{socket: socket, state: "active", mode: "commands", user: user, save: %{room_id: 1, stats: stats}, is_targeting: is_targeting}
    {:noreply, state} = Process.handle_cast({:apply_effects, [effect], {:npc, %{id: 1, name: "Bandit"}}, "description"}, state)
    assert state.save.stats.health == -5

    assert_received {:"$gen_cast", {:echo, ~s(description\n10 slashing damage is dealt.)}}
    assert_received {:"$gen_cast", {:died, {:user, _}}}
  after
    Session.Registry.unregister()
  end

  test "applying effects - died with zone graveyard", %{socket: socket} do
    Session.Registry.register(%{id: 2})

    @room.set_room(@room._room())
    @zone.set_zone(Map.put(@zone._zone(), :graveyard_id, 2))

    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 5}
    user = %{id: 2, name: "user", class: class_attributes(%{})}
    save = %{room_id: 1, stats: stats}

    state = %State{socket: socket, state: "active", mode: "commands", user: user, save: save, is_targeting: MapSet.new()}
    {:noreply, state} = Process.handle_cast({:apply_effects, [effect], {:npc, %{id: 1, name: "Bandit"}}, "description"}, state)

    assert state.save.stats.health == -5

    assert_receive :resurrect
    assert_receive {:"$gen_cast", {:teleport, 2}}
  after
    Session.Registry.unregister()
  end

  test "applying effects - died with no zone graveyard", %{socket: socket} do
    Session.Registry.register(%{id: 2})

    @room.set_room(@room._room())
    @zone.set_zone(Map.put(@zone._zone(), :graveyard_id, nil))
    @zone.set_graveyard({:error, :no_graveyard})

    effect = %{kind: "damage", type: :slashing, amount: 10}
    stats = %{health: 5}
    user = %{id: 2, name: "user", class: class_attributes(%{})}
    save = %{room_id: 1, stats: stats}

    state = %State{socket: socket, state: "active", mode: "commands", user: user, save: save, is_targeting: MapSet.new()}
    {:noreply, state} = Process.handle_cast({:apply_effects, [effect], {:npc, %{id: 1, name: "Bandit"}}, "description"}, state)

    assert state.save.stats.health == -5

    refute_receive {:"$gen_cast", {:teleport, _}}
  after
    Session.Registry.unregister()
  end

  describe "targeted" do
    test "being targeted tracks the targeter", %{socket: socket, user: user} do
      targeter = {:user, %{id: 10, name: "Player"}}

      {:noreply, state} = Process.handle_cast({:targeted, targeter}, %{socket: socket, user: user, target: nil, is_targeting: MapSet.new})

      assert state.is_targeting |> MapSet.size() == 1
      assert state.is_targeting |> MapSet.member?({:user, 10})
    end

    test "if your target is empty, set to the targeter", %{socket: socket, user: user} do
      targeter = {:user, %{id: 10, name: "Player"}}

      {:noreply, state} = Process.handle_cast({:targeted, targeter}, %{socket: socket, user: user, target: nil, is_targeting: MapSet.new})

      assert state.target == {:user, 10}
    end
  end

  test "a player removing a target stops tracking them", %{socket: socket} do
    targeter = {:user, %{id: 10, name: "Player"}}
    is_targeting = MapSet.new() |> MapSet.put({:user, 10})

    {:noreply, state} = Process.handle_cast({:remove_target, targeter}, %{socket: socket, is_targeting: is_targeting})

    assert state.is_targeting |> MapSet.size() == 0
    refute state.is_targeting |> MapSet.member?({:user, 10})
  end

  describe "target dying" do
    setup %{socket: socket} do
      target = {:user, %{id: 10, name: "Player"}}
      user = %{id: 10, class: class_attributes(%{})}

      state = %{
        socket: socket,
        state: "active",
        user: user,
        save: base_save(),
        target: {:user, 10},
        is_targeting: MapSet.new(),
      }

      %{state: state, target: target}
    end

    test "clears your target", %{state: state, target: target} do
      {:noreply, state} = Process.handle_cast({:died, target}, state)

      assert is_nil(state.target)
    end

    test "if other things are tracking you, select one to track", %{state: state, target: target} do
      is_targeting = MapSet.new() |> MapSet.put({:npc, 2})
      state = %{state | is_targeting: is_targeting}

      npc_spawner = %Data.NPCSpawner{id: 2, npc: struct(Data.NPC, npc_attributes(%{}))}
      Game.NPC.start_link(npc_spawner)

      {:noreply, state} = Process.handle_cast({:died, target}, state)

      assert state.target == {:npc, 2}
    end

    test "npc - a died message is sent and experience is applied", %{state: state} do
      target = {:npc, %{id: 10, name: "Bandit", level: 1, experience_points: 1200}}
      state = %{state | target: {:npc, 10}}

      {:noreply, state} = Process.handle_cast({:died, target}, state)

      assert is_nil(state.target)
      assert state.save.level == 2
    end
  end

  describe "channels" do
    setup do
      @socket.clear_messages()

      %{from: %{id: 10, name: "Player"}}
    end

    test "receiving a tell", %{socket: socket, from: from} do
      message = Message.tell(from, "howdy")

      {:noreply, state} = Process.handle_info({:channel, {:tell, {:user, from}, message}}, %{socket: socket})

      [{^socket, tell}] = @socket.get_echos()
      assert Regex.match?(~r/howdy/, tell)
      assert state.reply_to == {:user, from}
    end

    test "receiving a join" do
      {:noreply, state} = Process.handle_info({:channel, {:joined, "global"}}, %{save: %{channels: ["newbie"]}})
      assert state.save.channels == ["global", "newbie"]
    end

    test "does not duplicate channels list" do
      {:noreply, state} = Process.handle_info({:channel, {:joined, "newbie"}}, %{save: %{channels: ["newbie"]}})
      assert state.save.channels == ["newbie"]
    end

    test "receiving a leave" do
      {:noreply, state} = Process.handle_info({:channel, {:left, "global"}}, %{save: %{channels: ["global", "newbie"]}})
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
      {:noreply, state} = Process.handle_cast({:teleport, room.id}, %{socket: socket, user: user, save: user.save})
      assert state.save.room_id == room.id
    end
  end

  describe "resurrection" do
    test "sets health to 1 if < 0", state do
      save = %{stats: %{health: -1}}
      state = %{state | save: save}

      {:noreply, state} = Process.handle_info(:resurrect, state)

      assert state.save.stats.health == 1
      assert state.user.save.stats.health == 1
    end

    test "does not touch health if > 0", state do
      save = %{stats: %{health: 2}}
      state = %{state | save: save}

      {:noreply, state} = Process.handle_info(:resurrect, state)

      assert state.save.stats.health == 2
    end
  end

  describe "event notification" do
    test "player enters the room", state do
      {:noreply, ^state} = Process.handle_cast({:notify, {"room/entered", {:user, %{id: 1, name: "Player"}}}}, state)

      assert_received {:"$gen_cast", {:echo, "{blue}Player{/blue} enters"}}
    end

    test "npc enters the room", state do
      {:noreply, ^state} = Process.handle_cast({:notify, {"room/entered", {:npc, %{id: 1, name: "Bandit"}}}}, state)

      assert_received {:"$gen_cast", {:echo, "{yellow}Bandit{/yellow} enters"}}
    end

    test "player leaves the room", state do
      {:noreply, ^state} = Process.handle_cast({:notify, {"room/leave", {:user, %{id: 1, name: "Player"}}}}, state)
      assert_received {:"$gen_cast", {:echo, "{blue}Player{/blue} leaves"}}
    end

    test "player leaves the room and they were the target", %{socket: socket} do
      state = %{target: {:user, 1}, socket: socket}
      {:noreply, state} = Process.handle_cast({:notify, {"room/leave", {:user, %{id: 1, name: "Player"}}}}, state)
      assert is_nil(state.target)
    end

    test "npc leaves the room", state do
      {:noreply, ^state} = Process.handle_cast({:notify, {"room/leave", {:npc, %{id: 1, name: "Bandit"}}}}, state)
      assert_received {:"$gen_cast", {:echo, "{yellow}Bandit{/yellow} leaves"}}
    end

    test "npc leaves the room and they were the target", %{socket: socket} do
      state = %{target: {:npc, 1}, socket: socket}
      {:noreply, state} = Process.handle_cast({:notify, {"room/leave", {:npc, %{id: 1, name: "Bandit"}}}}, state)
      assert is_nil(state.target)
    end
  end
end
