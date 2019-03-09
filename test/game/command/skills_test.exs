defmodule Game.Command.SkillsTest do
  use ExVenture.CommandCase

  alias Game.Character
  alias Game.Command.ParseContext
  alias Game.Command.Skills
  alias Game.Session

  doctest Skills

  setup do
    start_and_clear_skills()

    slash = create_skill(%{
      level: 1,
      name: "Slash",
      points: 2,
      command: "slash",
      description: "Slash",
      user_text: "Slash at your [target]",
      usee_text: "You were slashed at",
      effects: [%{kind: "damage", type: "slashing", amount: 5}],
    })
    insert_skill(slash)

    npc = %Character.Simple{id: 1, type: "npc", name: "Bandit"}

    user = base_user()
    save = %{base_save() | level: 1, stats: %{health_points: 20, strength: 10, skill_points: 10}, wearing: %{}, skill_ids: [slash.id]}
    character = %{base_character(user) | save: save}

    start_room(%{npcs: [npc], players: [Character.to_simple(character)]})

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

      assert_socket_echo "slash"
    end

    test "view skill information - all", %{state: state} do
      :ok = Skills.run({:all}, state)

      assert_socket_echo "slash"
    end
  end

  describe "using a skill" do
    test "with a target", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: %Character.Simple{type: "npc", id: 1}}

      {:skip, :prompt, state} = Skills.run({slash, "slash"}, state)

      assert state.save.stats.skill_points == 8
      assert state.skills[slash.id]

      assert_socket_echo "slash"
    end

    test "required target - targets self", %{state: state, save: save, slash: slash} do
      Session.Registry.register(state.character)

      state = %{state | save: Map.merge(save, %{room_id: 1}), target: %Character.Simple{type: "npc", id: 1}}
      slash = %{slash | require_target: true}

      {:skip, :prompt, state} = Skills.run({slash, "slash"}, state)

      assert state.save.stats.skill_points == 8
      assert state.skills[slash.id]
      assert %{type: "npc", id: 1} = state.target

      assert_socket_echo "slash"

      assert_received {:"$gen_cast", {:apply_effects, _, _, _}}
    end

    test "required target - target added", %{state: state, save: save, slash: slash} do
      Session.Registry.register(state.character)

      state = %{state | save: Map.merge(save, %{room_id: 1}), target: %Character.Simple{type: "npc", id: 1}}
      slash = %{slash | require_target: true}

      {:skip, :prompt, state} = Skills.run({slash, "slash bandit"}, state)

      assert state.save.stats.skill_points == 8
      assert state.skills[slash.id]
      assert %{type: "npc", id: 1} = state.target

      assert_socket_echo "slash"

      refute_received {:"$gen_cast", {:apply_effects, _, _, _}}
    end

    test "set your target", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: nil}

      {:skip, :prompt, state} = Skills.run({slash, "slash bandit"}, state)

      assert state.save.stats.skill_points == 8
      assert %{type: "npc", id: 1} = state.target

      assert_socket_echo ""
      assert_socket_echo "slash"
    end

    test "change your target", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: %Character.Simple{type: "player", id: 3}}

      {:skip, :prompt, state} = Skills.run({slash, "slash bandit"}, state)

      assert state.save.stats.skill_points == 8
      assert state.target == %Character.Simple{id: 1, type: "npc", name: "Bandit"}

      assert_socket_echo ""
      assert_socket_echo "slash"
    end

    test "target not found", %{state: state, save: save, slash: slash} do
      state = %{state | save: Map.merge(save, %{room_id: 1}), target: %{type: "npc", id: 2}}
      :ok = Skills.run({slash, "slash"}, state)

      assert_socket_echo "your target could not"
    end

    test "with no target", %{state: state, slash: slash} do
      :ok = Skills.run({slash, "slash"}, %{state | target: nil})

      assert_socket_echo "you don't have"
    end

    test "not enough skill points", %{state: state, save: save, slash: slash} do
      stats = %{save.stats | skill_points: 1}
      state = %{state | save: Map.merge(save, %{room_id: 1, stats: stats}), target: %Character.Simple{type: "npc", id: 1}}

      {:update, ^state} = Skills.run({slash, "slash"}, state)

      assert_socket_echo "you don't have"
    end

    test "too soon", %{state: state, save: save, slash: slash} do
      state =
        state
        |> Map.put(:skills, %{slash.id => Timex.now()})
        |> Map.put(:save, Map.merge(save, %{room_id: 1}))
        |> Map.put(:target, %Character.Simple{type: "npc", id: 1})

      :ok = Skills.run({slash, "slash"}, state)

      assert_socket_echo "not ready"
    end

    test "not high enough level", %{state: state, save: save, slash: slash} do
      state = %{state |save: Map.merge(save, %{room_id: 1}), target: %Character.Simple{type: "npc", id: 1}}
      slash = %{slash | level: 2}

      :ok = Skills.run({slash, "slash"}, state)

      assert_socket_echo "not high enough"
    end
  end
end
