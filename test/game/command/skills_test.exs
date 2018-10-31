defmodule Game.Command.SkillsTest do
  use Data.ModelCase
  doctest Game.Command.Skills

  alias Game.Command.ParseContext
  alias Game.Command.Skills
  alias Game.Session

  @socket Test.Networking.Socket
  @room Test.Game.Room

  setup do
    @socket.clear_messages()
    start_and_clear_skills()

    slash = create_skill(%{
      level: 1,
      name: "Slash",
      points: 2,
      command: "slash",
      description: "Slash",
      user_text: "Slash at your {target}",
      usee_text: "You were slashed at",
      effects: [%{kind: "damage", type: "slashing", amount: 5}],
    })
    insert_skill(slash)

    npc = %{id: 1, name: "Bandit"}

    user = base_user()
    save = %{base_save() | level: 1, stats: %{health_points: 20, strength: 10, skill_points: 10}, wearing: %{}, skill_ids: [slash.id]}
    character = %{base_character(user) | save: save}

    room =
      @room._room()
      |> Map.put(:npcs, [npc])
      |> Map.put(:players, [user])

    @room.set_room(room)

    state = session_state(%{
      skills: %{},
      user: user,
      character: character,
      save: save
    })

    %{state: state, user: user, save: save, slash: slash}
  end

  describe "parsing skills" do
    setup %{state: state} do
      context = %ParseContext{player: state.character}
      %{context: context}
    end

    test "parsing skills based on the user", %{context: context, slash: slash} do
      assert %{text: "slash", module: Skills, args: {^slash, "slash"}} = Skills.parse_skill("slash", context)
      assert {:error, :bad_parse, "look"} = Skills.parse_skill("look", context)
    end

    test "parses the skill but marks as not high enough level if they have the skill but too low", %{state: state} do
      kick = create_skill(%{
        level: 2,
        name: "Kick",
        points: 2,
        command: "kick",
        description: "Kick",
        user_text: "Kick at your {target}",
        usee_text: "You were kicked at",
        effects: [%{kind: "damage", type: "bludgeoning", amount: 0}],
      })
      insert_skill(kick)

      character = state.character
      character = %{character | save: %{character.save | skill_ids: [kick.id | character.save.skill_ids]}}
      context = %ParseContext{player: character}

      assert %{text: "kick", module: Skills, args: {^kick, :level_too_low}} = Skills.parse_skill("kick", context)
    end

    test "parses the skill but marks as not usable if skill exists but user does not have", %{context: context} do
      kick = create_skill(%{
        level: 1,
        name: "Kick",
        points: 2,
        command: "kick",
        description: "Kick",
        user_text: "Kick at your {target}",
        usee_text: "You were kicked at",
        effects: [%{kind: "damage", type: "bludgeoning", amount: 0}],
      })
      insert_skill(kick)

      assert %{text: "kick", module: Skills, args: {^kick, :not_known}} = Skills.parse_skill("kick", context)
    end
  end

  describe "viewing skills" do
    setup do
      %{level: 5, name: "Kick"}
      |> create_skill()
      |> insert_skill()

      :ok
    end

    test "view skill information", %{state: state} do
      :ok = Skills.run({}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(slash), look)
      assert Regex.match?(~r(2sp), look)

      refute Regex.match?(~r(kick)i, look)
    end

    test "view skill information -all", %{state: state} do
      :ok = Skills.run({:all}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(slash)i, look)
      refute Regex.match?(~r(kick)i, look)
    end
  end

  describe "using a skill" do
    test "with a target", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}

      {:skip, :prompt, state} = Skills.run({slash, "slash"}, state)
      assert state.save.stats.skill_points == 8
      assert state.skills[slash.id]

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Slash), look)
    end

    test "required target - targets self", %{state: state, save: save, slash: slash} do
      Session.Registry.register(state.character)

      state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}
      slash = %{slash | require_target: true}

      {:skip, :prompt, state} = Skills.run({slash, "slash"}, state)

      assert state.save.stats.skill_points == 8
      assert state.skills[slash.id]
      assert state.target == {:npc, 1}

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Slash), look)

      assert_received {:"$gen_cast", {:apply_effects, _, _, _}}
    end

    test "required target - target added", %{state: state, save: save, slash: slash} do
      Session.Registry.register(state.character)

      state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}
      slash = %{slash | require_target: true}

      {:skip, :prompt, state} = Skills.run({slash, "slash bandit"}, state)

      assert state.save.stats.skill_points == 8
      assert state.skills[slash.id]
      assert state.target == {:npc, 1}

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Slash), look)

      refute_received {:"$gen_cast", {:apply_effects, _, _, _}}
    end

    test "set your target", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: nil}

      {:skip, :prompt, state} = Skills.run({slash, "slash bandit"}, state)
      assert state.save.stats.skill_points == 8
      assert state.target == {:npc, 1}

      [_, {_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Slash), look)
    end

    test "change your target", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:player, 3}}

      {:skip, :prompt, state} = Skills.run({slash, "slash bandit"}, state)
      assert state.save.stats.skill_points == 8
      assert state.target == {:npc, 1}

      [_, {_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Slash), look)
    end

    test "target not found", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: {:npc, 2}}
      :ok = Skills.run({slash, "slash"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(Your target could not), look)
    end

    test "with no target", %{state: state, slash: slash} do
      :ok = Skills.run({slash, "slash"}, %{state | target: nil})

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You don't have), look)
    end

    test "not enough skill points", %{state: state, save: save, slash: slash} do
      stats = %{save.stats | skill_points: 1}
      state = %{state | save: Map.merge(save, %{room_id: 1, stats: stats}), target: {:npc, 1}}

      {:update, ^state} = Skills.run({slash, "slash"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You don't have), look)
    end

    test "too soon", %{state: state, save: save, slash: slash} do
      state =
        state
        |> Map.put(:skills, %{slash.id => Timex.now()})
        |> Map.put(:save, Map.merge(save, %{room_id: 1}))
        |> Map.put(:target, {:npc, 1})

      :ok = Skills.run({slash, "slash"}, state)

      [{_socket, look} | _] = @socket.get_echos()
      assert Regex.match?(~r(not ready)i, look)
    end

    test "not high enough level", %{state: state, save: save, slash: slash} do
      state = %{state |save: Map.merge(save, %{room_id: 1}), target: {:npc, 1}}
      slash = %{slash | level: 2}

      :ok = Skills.run({slash, "slash"}, state)

      [{_socket, look}] = @socket.get_echos()
      assert Regex.match?(~r(You are not high), look)
    end
  end
end
